require 'csv'
class ProjectSourcesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_project

  def new
    @new_source_list ||= NewSourceList.new
    @source_list = SourceList.new project: @project
    master_name = @project.master_collection.name
    @collection_ids = AppContext.resmap_api.collections.all.select{|c| c.sites.count > 0 && c.name != master_name}.map{|c| [c.name, c.id]}
  end

  def create_from_file
    @new_source_list = NewSourceList.new(params[:new_source_list])

    if @new_source_list.valid?
      @source_list = @new_source_list.create_in_project(@project)
      redirect_to after_create_project_source_path(@project, @source_list)
    else
      new
      render 'new'
    end
  end

  def create_from_collection
    source_list = SourceList.new project: @project, collection_id: params[:source_list][:collection_id] if params[:source_list] && params[:source_list][:collection_id].present?
    if source_list.present? && source_list.valid?
      source_list.save
      source_list.import_sites_from_resource_map
      redirect_to project_path(@project)
    else
      new
      render 'new'
    end
  end

  def after_create
    iw = @source.as_collection.import_wizard

    if iw.status == 'finished'
      return redirect_to source_list_details_project_source_path(@project, @source)
    end

    raise "invalid import wizard state: #{iw.status}" if iw.status != 'file_uploaded'
    @columns_spec = iw.guess_columns_spec
    @sites_to_import = iw.sites_count(@columns_spec)
  end

  def source_list_details
    if @source.as_collection.import_wizard.status == 'file_uploaded'
      redirect_to after_create_project_source_path(@project, @source)
    end

    if @source.site_mappings.count == 0
      @source.import_sites_from_resource_map
    end

    @curation_progress = @source.curation_progress
    @mapping_progress = @source.mapping_progress
  end

  def index
    res = @project.source_lists.map do |s|
      h = s.as_json
      h["name"] = s.name
      h
    end

    render json: res
  end

  def unmapped_csv_download
    csv_string = @source.unmapped_sites_csv
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@project.name}")
  end

  def promote_facilities
    if @source.current_site_mappings.count == 0
      render 'mapping_property_not_set'
      return
    end

    @sites_to_promote_url = AppContext.resmap_url_to_recon(@source.sites_not_curated.url)
  end

  def promote_site
    if @source.promote_to_master(params[:site_id])
      status = 'ok'
    else
      status = 'fail'
    end
    render json: {status: status}
  end

  def process_automapping
    # corrections = flatten_corrections(params[:corrections]) || {}
    # error_tree, count = @source.process_automapping(params[:chosen_fields], corrections)
    error_tree, count = @source.process_automapping(params[:chosen_fields])
    render json: {error_tree: error_tree, count: count, mapping_progress: @source.mapping_progress}
  end

  protected

  def load_project
    @project = load_project_by_id(params[:project_id])
    @source = @project.source_lists.find(params[:id]) if params[:id].present?
  end

  # def flatten_corrections(error_tree, corrections={})
  #   return unless error_tree
  #   corrections ||= {}
  #   error_tree.each do |branch|
  #     corrections[branch[:name]] = branch[:correction] if branch[:correction]
  #     corrections[branch[:name]] = branch[:fixed] if branch[:fixed]
  #     corrections.merge!(flatten_corrections(branch[:sub], corrections)) if branch[:sub]
  #   end
  #   corrections
  # end

end
