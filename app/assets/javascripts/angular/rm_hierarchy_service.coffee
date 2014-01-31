class NodeService
  constructor: (hierarchy = null) ->
    @root_nodes = []
    @nodes_by_id = {}
    if hierarchy
      @_prepare_nodes(hierarchy, null)

  roots: ->
    @root_nodes

  node_by_id: (id) ->
    @nodes_by_id[id] ||= {}

  _load_nodes: (RmMetadataService, collection_id, field_id) ->
    RmMetadataService.hierarchy(collection_id, field_id).then (hierarchy) =>
      @_prepare_nodes(hierarchy, null)

  _prepare_nodes: (nodes, parent_id) ->
    for node in nodes
      # keep instances of nodes_by_id
      node = _.assign(@node_by_id(node.id), node)
      # replace node instance in parent
      if parent_id != null
        child = _.find(@nodes_by_id[parent_id].sub, (subNode) ->
          subNode.id == node.id
        )
        index = @nodes_by_id[parent_id].sub.indexOf(child)
        @nodes_by_id[parent_id].sub[index] = node
      else
        @root_nodes.push(node)

      @nodes_by_id[node.id] = node
      node.parent_id = parent_id
      node.leaf = !(node.sub? && node.sub.length > 0)

      if parent_id != null
        path_prefix = @nodes_by_id[parent_id].path + ' \\ '
      else
        path_prefix = ''
      node.path = path_prefix + node.name
      if !node.leaf
        @_prepare_nodes(node.sub, node.id)

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
