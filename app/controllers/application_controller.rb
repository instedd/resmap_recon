class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :setup_app_context

  protected

  def setup_app_context
    AppContext.resmap_api = ResmapApi.new
  end
end
