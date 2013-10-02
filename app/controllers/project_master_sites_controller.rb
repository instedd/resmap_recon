class ProjectMasterSitesController < ApplicationController
  require 'csv'

  def search
    @project = Project.find(params[:project_id])

    sites = @project.master_collection.sites
    if params[:id].present?
      sites = [sites.find(params[:id])]
    else
      sites = sites.where(search: params[:search])
    end

    render json: sites.map(&:to_hash)
  end

  def update
    @project = Project.find(params[:project_id])
    master_site = @project.master_collection.sites.find(params[:id])
    master_site.update_properties(params[:target_site])

    source_list = @project.source_lists.find(params[:source_site][:source_list_id])

    source_list.consolidate_with(params[:source_site][:id], params[:id])

    render nothing: true
  end

  def consolidated_sites
    @project = Project.find(params[:project_id])
    render json: @project.consolidated_with(params[:id])
  end

  def csv_download
    @project = Project.find(params[:project_id])
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
end
