class ProjectSourcesSitesController < ApplicationController

  def dismiss
    Project
      .find(params[:project_id])
      .dismiss_source_site(params[:source_id], params[:id])

    render nothing: true
  end

end
