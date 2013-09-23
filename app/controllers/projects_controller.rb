class ProjectsController < ApplicationController
  def index
    @projects = Project.all
  end

  def show
    @project = Project.find(params[:id])
  end

  def import_wizard
    @project = Project.find(params[:id])
    collection = @project.source_collection_by_id params[:collection][:id].to_i
    if !collection.nil?
      redirect_to collection.import_wizard_url
    else
      render :status => 404
    end
  end

  def curate
    @project = Project.find(params[:id])
    @hierarchy = @project.target_field.hierarchy
  end

  def pending_changes
    @project = Project.find(params[:id])
    render json: @project.pending_changes(params[:node_id])
  end
end
