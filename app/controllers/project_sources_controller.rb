class ProjectSourcesController < ApplicationController
  def review_mapping
    @project = Project.find(params[:project_id])
    if params[:id].present?
      @source = @project.source_lists.find(params[:id])

      @hierarchy = @project.target_field.hierarchy
    end
  end
end
