class ProjectSourcesController < ApplicationController
  def review_mapping
    @project = Project.find(params[:project_id])
    if params[:id].present?
      @source = @project.source_lists.find(params[:id])
    end
  end
end
