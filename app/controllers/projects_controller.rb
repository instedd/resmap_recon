class ProjectsController < ApplicationController
  before_filter :setup_templates, only: [:new, :create]

  def index
    @projects = Project.all
  end

  def show
    @project = Project.find(params[:id])
  end

  def curate
    @project = Project.find(params[:id])
    @hierarchy = @project.target_field.hierarchy
  end

  def pending_changes
    @project = Project.find(params[:id])
    render json: @project.pending_changes(params[:target_value])
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(name: params[:project][:name])

    if @project.valid?
      apply_template(@project, params[:project][:template])
      @project.save!

      redirect_to project_path(@project)
    else
      render 'new'
    end
  end

  protected

  def setup_templates
    @templates = ['Kenya MFL', 'USA MFL']
  end

  def apply_template(project, template)
    collection = AppContext.resmap_api.collections.create name: project.name

    hierarchy = nil
    if template == 'Kenya MFL'
      hierarchy = prepare_hierarchy(YAML::load_file(File.join(Rails.root, "config", "kenya_hierarchy.yml")))
    end

    layer = collection.find_or_create_layer_by_name('Main')
    layer.ensure_fields [
      { name: 'Facility Code', code: 'fcode', kind: 'text' },
      { name: 'Facility Type', code: 'ftype', kind: 'text' },
      { name: 'Beds', code: 'beds', kind: 'numeric' },
      { name: 'Administrative Division', code: 'admin_division', kind: 'hierarchy', config: { hierarchy: hierarchy } }
    ]

    project.master_collection_id = collection.id
    project.master_collection_target_field_id = collection.field_by_code('admin_division').id
  end

  def prepare_hierarchy(hierarchy)
    res = {}
    hierarchy.each_with_index do |n,i|
      res[i] = { 'id' => n['id'], 'name' => n['name'] }
      res[i]['sub'] = prepare_hierarchy(n['sub']) unless n['sub'].nil?
    end

    res
  end
end
