class ProjectSourcesImportWizardController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_project

  def status
    render json: { status: @import_wizard.status }
  end

  def validate
    columns_spec = JSON.parse(params[:columns_spec])
    render json: { valid: @import_wizard.is_column_spec_valid?(columns_spec) }
  end

  def start
    columns_spec = params[:columns_spec]
    @import_wizard.execute(columns_spec)
    render nothing: true
  end

  protected

  def load_project
    @project = load_project_by_id(params[:project_id])
    @source = @project.source_lists.find(params[:id]) if params[:id].present?
    @import_wizard = @source.as_collection.import_wizard
  end


end
