require File.dirname(__FILE__) + '/project_fixtures'
require File.dirname(__FILE__) + '/module_node_fixtures'
require File.dirname(__FILE__) + '/module_result_fixtures'

class ProjectResultFixtures

  def self.qt_calculator
    result = Kalibro::Entities::ProjectResult.new
    result.project = ProjectFixtures.project
    result.date = ModuleResultFixtures.create.date
    result.load_time = 14878
    result.analysis_time = 1022
    result.source_tree = ModuleNodeFixtures.qt_calculator_tree
    result.collect_time = 14878
    result
  end

  def self.qt_calculator_hash
    {:project => ProjectFixtures.project_hash, :date => ModuleResultFixtures.create_hash[:date],
      :load_time => 14878, :analysis_time => 1022, :source_tree => ModuleNodeFixtures.qt_calculator_tree_hash, 
      :collect_time => 14878}
  end
    
end
