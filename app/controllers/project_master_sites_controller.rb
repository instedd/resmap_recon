class ProjectMasterSitesController < ApplicationController
  require 'csv'
  before_filter :load_project

  def search
    sites = @project.master_collection.sites
    if params[:id].present?
      sites = [sites.find(params[:id])]
    else
      sites = sites.where(search: params[:search])
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

  def csv_download
    csv_string = CSV.generate do |csv|
      fields = @project.master_collection.fields
      csv << ['Facility Name', 'Lat', 'Long'] + fields.map(&:name) + ['IsArea']
      @project.master_collection.sites.each do |site|
        p = site['properties']
        csv << [site['name'], site['lat'], site['long']] + fields.map{|f| p[f.code]} + ["1"]
      end
    end
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@project.name}")
  end

  protected

  def load_project
    @project = Project.find(params[:project_id])
  end

  def consolidate_with_master_site(master_site)
    master_site.update_properties(params[:target_site])
    source_list = @project.source_lists.find(params[:source_site][:source_list_id])
    source_list.consolidate_with(params[:source_site][:id], master_site.id)
  end
end
