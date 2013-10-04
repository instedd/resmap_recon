class ProjectsController < ApplicationController
  def index
    @projects = Project.all
  end

  def show
    @project = Project.find(params[:id])
  end

  def curate
    @project = Project.find(params[:id])
    @hierarchy = @project.target_field.hierarchy
  end

  def pending_changes
    @project = Project.find(params[:id])
    render json: @project.pending_changes(params[:target_value])
  end
end
