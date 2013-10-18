require 'csv'
class ProjectSourcesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_project

  def new
    @new_source_list = NewSourceList.new
    @source_list = SourceList.new project: @project
    @collection_ids = AppContext.resmap_api.collections.all.map{|c| [c.name, c.id]}
  end

  def create_from_file
    @new_source_list = NewSourceList.new(params[:new_source_list])

    if @new_source_list.valid?
      @source_list = @new_source_list.create_in_project(@project)
      redirect_to after_create_project_source_path(@project, @source_list)
    else
      render 'new'
    end
  end

  def create_from_collection
    source_list = SourceList.new project: @project, collection_id: params[:source_list][:collection_id]
    if source_list.valid?
      source_list.save
      redirect_to project_path(@project)
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
    if @source.as_collection.sites.count == 0
      redirect_to after_create_project_source_path(@project, @source)
    end

    @hierarchy = @project.target_field.hierarchy
    @curation_progress = "#{@source.curation_progress}%"
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
    @source.mapping_property_id = params[:mapping_property_id]
    @source.save!
    render nothing: true
  end

  def unmapped_csv_download
    csv_string = @source.unmapped_sites_csv
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@project.name}")
  end

  protected

  def load_project
    @project = load_project_by_id(params[:project_id])
    @source = @project.source_lists.find(params[:id]) if params[:id].present?
  end

end
