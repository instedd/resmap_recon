class ProjectSourcesSitesController < ApplicationController
  before_filter :authenticate_user!

  def dismiss
    Project
      .find(params[:project_id])
      .dismiss_source_site(params[:source_id], params[:id])

    render nothing: true
  end

end
