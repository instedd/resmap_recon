class ProjectMasterSitesController < ApplicationController
  require 'csv'
  before_filter :authenticate_user!
  before_filter :load_project

  def index
  end

  def search
    sites = @project.master_collection.sites
    if params[:id].present?
      sites = [sites.find(params[:id])]
    elsif params[:search].present?
      sites = sites.where(search: params[:search])
    else
      sites = sites.all
    end

    render json: sites.map(&:to_hash)
  end

  def update
    site = @project.master_collection.sites.find(params[:id])
    consolidate_with_master_site(site)
    render nothing: true
  end

  def create
    params[:target_site].delete(:id) # it is null and we don't want it
    site = @project.master_collection.sites.create(name: params[:target_site][:name])
    consolidate_with_master_site(site)
    render nothing: true
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

    if params.has_key?(:source_site)
      source_list = @project.source_lists.find(params[:source_site][:source_list_id])
      source_list.consolidate_with(params[:source_site][:id], master_site.id)
    end
  end
end
