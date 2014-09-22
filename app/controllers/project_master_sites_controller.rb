class ProjectMasterSitesController < ApplicationController
  require 'csv'
  before_filter :authenticate_user!
  before_filter :load_project

  def index
  end

  def search
    page = 1
    if params[:id].present?
      sites = [@project.master_collection.sites.find(params[:id])]
    else
      page = params[:page] || 1
      sites = @project.search_mfl(hierarchy: params[:hierarchy], search: params[:search], page: page, page_size: 5)
    end

    headers = []
    @project.master_collection.fields.each{|f| headers << {name: f.name, code: f.code}}

    # TODO support paging
    render json: { items: sites.map(&:to_hash), headers: headers, current_page: page, total_count: sites.total_count }
  end

  def update
    begin
      site = @project.master_collection.sites.find(params[:id])
      consolidate_with_master_site(site)
      render nothing: true
    rescue ResourceMap::SiteValidationError => e
      render json: { validation_errors: e.errors_by_property_code }
    end
  end

  def create
    begin
      params[:target_site].delete(:id) # it is null and we don't want it
      site = @project.master_collection.sites.create(name: params[:target_site][:name])
      consolidate_with_master_site(site)
      render nothing: true
    rescue ResourceMap::SiteValidationError => e
      render json: { validation_errors: e.errors_by_property_code }      
    end
  end

  def consolidated_sites
    render json: @project.consolidated_with(params[:id])
  end

  def history
    @site = @project.master_collection.sites.find(params[:id])
    @history = @site.history.sort_by{|h| h['created_at']}.reverse
  end

  def csv_download
    csv_string = CSV.generate do |csv|
      fields = @project.master_collection.fields

      @hierarchy_field = @project.target_field
      @fields_to_export = fields.select { |f| f.id != @hierarchy_field.id }

      csv << [@hierarchy_field.name, 'Facility Name', 'Source', 'Source ID'] + @fields_to_export.map(&:name) + ['Lat', 'Long', 'IsArea']
      sites = @project.master_collection.sites.all

      @hierarchy = @project.target_field.hierarchy

      append_sites_for_node(csv, "", @hierarchy, sites)

      # render pending sites (in case something messed up the data)
      sites.each do |site|
        append_site_to_csv(csv, '(none)', site)
      end
    end
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@project.name}")
  end

  def csv_download_from_rm
    redirect_to @project.master_collection.csv_url
  end

  def find_duplicates
    sites = @project.master_collection.sites
    sites = sites.where(name: params[:name])
    sites = sites.where("#{@project.target_field.code}[under]" => params[:hierarchy]) if params[:hierarchy]
    render json: {duplicate: sites.count > 0}
  end

  protected

  def append_sites_for_node(csv, path, hierarchy, sites)
    hierarchy.each do |node|
      p = "#{path}#{'\\' unless path.blank?}#{node['name']}"

      append_hierarchy_to_csv(csv, p, node)

      sites.select! do |site|
        if site.to_hash['properties'][@hierarchy_field.code] == node['id']
          append_site_to_csv(csv, p, site)
          # remove from sites
          false
        else
          true
        end
      end

      append_sites_for_node(csv, p, node['sub'], sites) unless node['sub'].nil?
    end
  end

  def append_site_to_csv(csv, hierarchy_full_path, site)
    csv << [hierarchy_full_path, site.to_hash['name'], @project.master_collection.name, site.id] + @fields_to_export.map{|f| site.to_hash['properties'][f.code]} + [site.to_hash['lat'], site.to_hash['long'], "0"]
  end

  def append_hierarchy_to_csv(csv, hierarchy_full_path, node)
    csv << [hierarchy_full_path, "", @project.master_collection.name, node['id']] + @fields_to_export.map{|f| ""} + ["", "", "1"]
  end

  def load_project
    @project = load_project_by_id(params[:project_id])
  end

  def consolidate_with_master_site(master_site)  
    master_site.update_properties(params[:target_site])

    if params[:source_sites]
      params[:source_sites].each do |source_site|
        source_list = @project.source_lists.find(source_site[:source_list_id])
        source_list.consolidate_with(source_site[:id], master_site.id)
      end
    end
  end
end
