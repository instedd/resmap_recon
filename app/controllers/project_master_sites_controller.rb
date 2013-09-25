class ProjectMasterSitesController < ApplicationController

  def search
    @project = Project.find(params[:project_id])
    sites = @project.master_collection
      .sites_where(search: params[:search])

    render json: sites
  end
end
