require 'csv'
class ProjectSourcesController < ApplicationController
  before_filter :load_project

  def new
    @new_source_list = NewSourceList.new
  end

  def create
    @new_source_list = NewSourceList.new(params[:new_source_list])

    if @new_source_list.valid?
      @source_list = @new_source_list.create_in_project(@project)
      redirect_to after_create_project_source_path(@project, @source_list)
    else
      render 'new'
    end
  end

  def after_create
    iw = @source.as_collection.import_wizard
    raise 'invalid import wizard state' if iw.status != 'file_uploaded'
    @columns_spec = iw.guess_columns_spec
    @sites_to_import = iw.sites_count(@columns_spec)
  end

  def source_list_details
    @project = Project.find(params[:project_id])
    @source = @project.source_lists.find(params[:id])
    @hierarchy = @project.target_field.hierarchy
    unless @source.as_collection.sites.all.count == 0
      @curation_progress = "#{100 - (@source.sites_not_curated.count * 100 / @source.as_collection.sites.all.count)}%"
    end
  end

  def review_mapping
    if params[:id].present?
      @hierarchy = @project.target_field.hierarchy
    end
  end

  def update_mapping_entry
    @source.update_mapping_entry!(params[:entry])
    render nothing: true
  end

  def update_mapping_property
    @source = @project.source_lists.find(params[:id])
    @source.mapping_property_id = params[:mapping_property_id]
    render nothing: true
  end

  def unmapped_csv_download
    @source = @project.source_lists.find(params[:id])
    csv_string = @source.unmapped_sites_csv
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@project.name}")
  end

  protected

  def load_project
    @project = Project.find(params[:project_id])
    @source = @project.source_lists.find(params[:id]) if params[:id].present?
  end

end
