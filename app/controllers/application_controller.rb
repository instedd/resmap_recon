class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :setup_app_context
  before_filter do
    GA.tracker = Settings.google_analytics
  end

  protected

  def current_user
    @current_user ||= begin
      if session[:email].blank? || session[:password].blank?
        nil
      else
        User.find_by_email(session[:email])
      end
    end
  end

  helper_method :current_user

  def setup_app_context
    AppContext.resmap_api = ResourceMap::Api.basic_auth(session[:email], session[:password], Settings.resource_map.host, Settings.resource_map.https)
  end

  def authenticate_user!
    if current_user.nil?
      if request.xhr?
        raise 'Session lost'
      end
      redirect_to new_session_path
    end
  end

  def load_project_by_id(id)
    current_user.projects.find(id)
  end
end
