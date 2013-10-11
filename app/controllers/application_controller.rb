class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :setup_app_context

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
    if current_user.nil?
      AppContext.resmap_api = ResmapApi.public
    else
      AppContext.resmap_api = ResmapApi.basic(session[:email], session[:password])
    end
  end

  def authenticate_user!
    if current_user.nil?
      redirect_to new_session_path
    end
  end
end
