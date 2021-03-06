class ProjectSourcesImportWizardController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_project

  def status
    begin
      render json: { status: @import_wizard.status }
    rescue
      upload_error
    end
  end

  def validate
    begin
      columns_spec = params[:columns_spec]
      render json: { valid: @import_wizard.is_column_spec_valid?(columns_spec), errors: @import_wizard.column_spec_errors(columns_spec).keys.map(&:humanize).join(', ') }
    rescue
      upload_error
    end     
  end

  def start
    begin
      columns_spec = params[:columns_spec]
      @import_wizard.execute(columns_spec)
      render nothing: true
    rescue
      upload_error
    end
  end

  protected

  def load_project
    @project = load_project_by_id(params[:project_id])
    @source = @project.source_lists.find(params[:id]) if params[:id].present?
    @import_wizard = @source.as_collection.import_wizard
  end

  def upload_error
    render 'shared/upload_error'
  end
end
