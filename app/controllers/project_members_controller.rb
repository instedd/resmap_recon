class ProjectMembersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_project

  def index
  end

  protected

  def load_project
    @project = load_project_by_id(params[:project_id])
  end
end
