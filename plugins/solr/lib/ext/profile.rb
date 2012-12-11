require_dependency 'profile'

class Profile
  after_save_reindex [:articles], :with => :delayed_job

  acts_as_faceted :fields => {
      :solr_plugin_f_enabled => {:label => _('Situation'), :type_if => proc { |klass| klass.kind_of?(Enterprise) },
        :proc => proc { |id| solr_plugin_f_enabled_proc(id) }},
      :solr_plugin_f_region => {:label => _('City'), :proc => proc { |id| solr_plugin_f_region_proc(id) }},
      :solr_plugin_f_categories => {:multi => true, :proc => proc {|facet, id| solr_plugin_f_categories_proc(facet, id)},
        :label => proc { |env| solr_plugin_f_categories_label_proc(env) }, :label_abbrev => proc{ |env| solr_plugin_f_categories_label_abbrev_proc(env) }},
    }, :category_query => proc { |c| "solr_plugin_category_filter:#{c.id}" },
    :order => [:solr_plugin_f_region, :solr_plugin_f_categories, :solr_plugin_f_enabled]

  acts_as_searchable :fields => facets_fields_for_solr + [:extra_data_for_index,
      # searched fields
      {:name => {:type => :text, :boost => 2.0}},
      {:identifier => :text}, {:nickname => :text},
      # filtered fields
      {:solr_plugin_public => :boolean}, {:environment_id => :integer},
      {:solr_plugin_category_filter => :integer},
      # ordered/query-boosted fields
      {:name_sortable => :string}, {:user_id => :integer},
      :enabled, :active, :validated, :public_profile,
      {:lat => :float}, {:lng => :float},
      :updated_at, :created_at,
    ],
    :include => [
      {:region => {:fields => [:name, :path, :slug, :lat, :lng]}},
      {:categories => {:fields => [:name, :path, :slug, :lat, :lng, :acronym, :abbreviation]}},
    ], :facets => facets_option_for_solr,
    :boost => proc{ |p| 10 if p.enabled }

  private

  def self.solr_plugin_f_categories_label_proc(environment)
    ids = environment.top_level_category_as_facet_ids
    r = Category.find(ids)
    map = {}
    ids.map{ |id| map[id.to_s] = r.detect{|c| c.id == id}.name }
    map
  end

  def self.solr_plugin_f_categories_proc(facet, id)
    id = id.to_i
    return if id.zero?
    c = Category.find(id)
    c.name if c.top_ancestor.id == facet[:label_id].to_i or facet[:label_id] == 0
  end

  def solr_plugin_f_categories
    category_ids - [region_id]
  end

  def solr_plugin_f_region
    self.region_id
  end

  def self.solr_plugin_f_region_proc(id)
    c = Region.find(id)
    s = c.parent
    if c and c.kind_of?(City) and s and s.kind_of?(State) and s.acronym
      [c.name, ', ' + s.acronym]
    else
      c.name
    end
  end

  def self.solr_plugin_f_enabled_proc(enabled)
    enabled = enabled == "true" ? true : false
    enabled ? s_('facets|Enabled') : s_('facets|Not enabled')
  end

  def solr_plugin_f_enabled
    self.enabled
  end

  def solr_plugin_public
    self.public?
  end

  def solr_plugin_category_filter
    categories_including_virtual_ids
  end
end
