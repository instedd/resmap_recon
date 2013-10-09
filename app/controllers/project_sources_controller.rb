class ProjectSourcesController < ApplicationController
  before_filter :load_project

  def new
    @new_source_list = NewSourceList.new
  end

  def create
  end

  def source_list_details
    @project = Project.find(params[:project_id])
    @source = @project.source_lists.find(params[:id])
    @hierarchy = @project.target_field.hierarchy
  end

  def review_mapping
    if params[:id].present?
      @source = @project.source_lists.find(params[:id])

      @hierarchy = @project.target_field.hierarchy
    end
  end

  def update_mapping_entry
    @source = @project.source_lists.find(params[:id])
    @source.update_mapping_entry!(params[:entry])
    render nothing: true
  end

  def update_mapping_property
    @source = @project.source_lists.find(params[:id])
    @source.mapping_property_id = params[:mapping_property_id]
    render nothing: true
  end

  protected

  def load_project
    @project = Project.find(params[:project_id])
  end

end
