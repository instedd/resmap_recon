class ProjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_project, except: [:index, :new, :create]
  before_filter :setup_templates, only: [:new, :create]

  def index
    @projects = current_user.projects
  end

  def show
    @curation_progress = "#{@project.source_lists.map(&:curation_progress).reduce(:+) / @project.source_lists.count}%" rescue "0%"
  end

  def curate
    @hierarchy_field_id = @project.target_field.id
    @pending_changes_site_list = unify(@project.source_lists.map(&:mapped_hierarchy_counts))
    @source_lists = @project.source_lists.map do |s|
      h = s.as_json
      h["name"] = s.name
      h
    end
    @source_lists.insert 0, { "name" => "All sources" }
  end

  def pending_changes
    page = 1
    page = params[:page] if params[:page].present?

    changes = @project.pending_changes(params[:source_list_id], params[:target_value], params[:search].presence, page)

    data = { sites: changes[:sites], headers: changes[:headers], current_page: changes[:current_page], total_count: changes[:total_count] }

    render json: data
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(name: params[:project][:name])

    if @project.valid?
      apply_template(@project, params[:project][:template])
      @project.users << current_user
      @project.save!

      redirect_to project_path(@project)
    else
      render 'new'
    end
  end

  protected

  def setup_templates
    @templates = ['Kenya MFL', 'Tanzania MFL', 'Other Country']
  end

  def apply_template(project, template)
    collection = AppContext.resmap_api.collections.create name: project.name

    fields_to_create = Project::BASIC_FIELDS

    unless template == 'Other Country'
      raw_hierarchy = HierarchyTemplate.load(template)
      hierarchy = prepare_hierarchy(raw_hierarchy)
      fields_to_create.push({ name: 'Administrative Division', code: 'admin_division', kind: 'hierarchy', config: { hierarchy: hierarchy } })
      project.hierarchy = raw_hierarchy
    end

    layer = collection.find_or_create_layer_by_name 'Main'
    layer.ensure_fields fields_to_create

    project.master_collection_id = collection.id

    project.master_collection_target_field_id = collection.field_by_code('admin_division').id unless template == 'Other Country'
  end

  def prepare_hierarchy(hierarchy)
    res = []
    hierarchy.each_with_index do |n,i|
      res[i] = { 'id' => n['id'], 'name' => n['name'] }
      res[i]['sub'] = prepare_hierarchy(n['sub']) unless n['sub'].nil?
    end

    res
  end

  protected

  def load_project
    @project = load_project_by_id(params[:id])
  end

  def unify(mapped_counts)
    unified = {}
    unified.default = 0
    mapped_counts.each do |counts|
      counts.each do |k,v|
        unified[k] += v
      end
    end
    unified
  end

end
