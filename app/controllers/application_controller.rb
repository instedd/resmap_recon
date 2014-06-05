class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :setup_app_context
  before_filter do
    GA.tracker = Settings.google_analytics
  end

  rescue_from Project::NoHierarchyDefinedError do |error|
    render 'shared/no_hierarchy_defined'
  end

  rescue_from ResourceMap::ResourceMapApiError do |error|
    Rails.logger.error "#{Date.new} Error accessing Resource Map's API:\nHTTP STATUS: #{error.http_status_code}\nRM ERROR CODE: #{error.error_code}\nDESCRIPTION: #{error.message}"
    raise error
  end

  protected

  def setup_app_context
    if current_user
      AppContext.resmap_api = Rails.cache.fetch("resmap_api_#{current_user.email}", expires_in: 300) do
        ResourceMap::Api.trusted(current_user.email, Settings.resource_map.host, Settings.resource_map.https)
      end

      AppContext.setup_url_rewrite_from_request(request)
    end
  end

  def load_project_by_id(id)
    current_user.projects.find(id)
  end
end
