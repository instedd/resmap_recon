class ProjectMasterSitesController < ApplicationController

  def search
    @project = Project.find(params[:project_id])
    sites = @project.master_collection
      .sites_where(search: params[:search])

    render json: sites
  end

  def update
    @project = Project.find(params[:project_id])
    master_site = @project.master_collection.sites_find(params[:id])
    master_site.update_properties(params[:target_site])

    source_list = @project.source_lists.find(params[:source_site][:source_list_id])

    source_list.consolidate_with(params[:source_site][:id], params[:id])

    render nothing: true
  end

  def consolidated_sites
    @project = Project.find(params[:project_id])
    render json: @project.consolidated_with(params[:id])
  end
end
