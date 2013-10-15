class ProjectMembersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_project

  def index
  end

  def create
    email = params[:member][:email]

    invited = User.by_email(email)
    @project.users << invited

    flash.notice = "#{email} added to project"
    redirect_to project_members_path(@project)
  end

  def destroy
    user = @project.users.find(params[:id])
    @project.users.delete user
    flash.notice = "#{user.email} removed from project"
    redirect_to project_members_path(@project)
  end

  def typeahead
    render json: @project.master_collection.members.invitable(params[:q])
  end


  protected

  def load_project
    @project = load_project_by_id(params[:project_id])
  end
end
