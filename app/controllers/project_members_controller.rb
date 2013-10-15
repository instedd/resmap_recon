class ProjectMembersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_project

  def index
  end

  def create
    email = params[:member][:email]

    @project.master_collection.members.find_or_create_by_email(email).set_admin!
    @project.source_lists.each do |s|
      s.as_collection.members.find_or_create_by_email(email).set_admin!
    end

    invited = User.find_or_create_by_email!(email)
    @project.users << invited

    flash.notice = "#{email} added to project"
    redirect_to project_members_path(@project)
  end

  def destroy
    member = @project.users.find(params[:id])
    email = member.email

    @project.master_collection.members.find_or_create_by_email(email).delete!
    @project.source_lists.each do |s|
      s.as_collection.members.find_or_create_by_email(email).delete!
    end

    @project.users.delete member

    flash.notice = "#{email} removed from project"
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
