class NodeService
  constructor: (hierarchy = null) ->
    @root_nodes = []
    @nodes_by_id = {}
    if hierarchy
      @_prepare_nodes(hierarchy, null)
      @notify_on_load()

  on_load: (callback) ->
    if @loaded
      callback()
    else
      @callback = callback

  roots: ->
    @root_nodes

  node_by_id: (id) ->
    @nodes_by_id[id] ||= {}

  notify_on_load: ->
    @loaded = true
    @callback?()

  _load_nodes: (RmMetadataService, collection_id, field_id) ->
    RmMetadataService.hierarchy(collection_id, field_id).then (hierarchy) =>
      @_prepare_nodes(hierarchy, null)
      @notify_on_load()

  _prepare_nodes: (nodes, parent) ->
    for node in nodes
      # keep instances of nodes_by_id
      node = _.assign(@node_by_id(node.id), node)
      node.parent = parent
      # replace node instance in parent
      if parent != null
        node.parent_id = parent.id
        child = _.find(@nodes_by_id[parent.id].sub, (subNode) ->
          subNode.id == node.id
        )
        index = @nodes_by_id[parent.id].sub.indexOf(child)
        @nodes_by_id[parent.id].sub[index] = node
      else
        @root_nodes.push(node)

      @nodes_by_id[node.id] = node
      node.leaf = !(node.sub? && node.sub.length > 0)

      if parent != null
        path_prefix = @nodes_by_id[parent.id].path + ' \\ '
      else
        path_prefix = ''
      node.path = path_prefix + node.name
      if !node.leaf
        @_prepare_nodes(node.sub, node)

angular.module('RmHierarchyService', ['RmMetadataService'])

.factory 'RmHierarchyService', ($rootScope, RmMetadataService) ->

  return {
    for_hierarchy: (hierarchy) ->
      new NodeService(hierarchy)

    for: (collection_id, field_id) ->
      service = new NodeService()
      service._load_nodes(RmMetadataService, collection_id, field_id)
      service
  }
