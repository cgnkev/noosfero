class ContentViewerController < ApplicationController

  needs_profile

  inverse_captcha :field => 'e_mail'

  def view_page
    path = params[:page].join('/')

    if path.blank?
      @page = profile.home_page
      if @page.nil?
        render :action => 'no_home_page'
        return
      end
    else
      path.gsub!(/\/(\d{4})\/(\d{2})\Z/, '')
      year = $1
      month = $2

      @page = profile.articles.find_by_path(path)
      unless @page
        page_from_old_path = profile.articles.find_by_old_path(path)
        if page_from_old_path
          flash[:notice] = _("Redirected from \"%s\". please update your links and bookmarks.") % request.url
          redirect_to :profile => profile.identifier, :page => page_from_old_path.explode_path
          return
        end
      end

      # do not show unpublished articles
      if @page && !@page.published
        @page = nil
      end

      # page not found, give error
      if @page.nil?
        render_not_found(@path)
        return
      end
    end

    if !@page.public? && !request.ssl?
      return if redirect_to_ssl
    end

    if !@page.display_to?(user)
      # FIXME find a nice "access denied" layout
      render :action => 'access_denied', :status => 403, :layout => false
    end

    if @page.mime_type != 'text/html'
      headers['Content-Type'] = @page.mime_type
      data = @page.data

      # TODO test the condition
      if data.nil?
        raise "No data for file"
      end

      render :text => data, :layout => false
      return
    end

    if request.post? && params[:comment] && params[self.icaptcha_field].blank? && @page.accept_comments?
      add_comment
    end

    if request.post? && params[:remove_comment]
      remove_comment
    end
    
    if @page.blog?
      @page.filter = {:year => year, :month => month}
    end

    @comments = @page.comments(true)
  end

  protected

  def add_comment
    @comment = Comment.new(params[:comment])
    @comment.author = user if logged_in?
    @comment.article = @page
    if @comment.save
      @comment = nil # clear the comment form
    else
      @form_div = 'opened'
    end
  end

  def remove_comment
    @comment = @page.comments.find(params[:remove_comment])
    if (user == @comment.author || user == @page.profile || user.has_permission?(:moderate_comments, @page.profile))
      @comment.destroy
      flash[:notice] = _('Comment succesfully deleted')
    end
    redirect_to :action => 'view_page', :profile => params[:profile], :page => @page.explode_path
  end

end
