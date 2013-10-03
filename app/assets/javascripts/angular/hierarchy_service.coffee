angular.module('HierarchyService', [])

.factory 'HierarchyService', ($rootScope) ->

  root_nodes = $rootScope.hierarchy
  nodes_by_id = {}

  prepare_nodes = (nodes, parent_id) ->
    for node in nodes
      nodes_by_id[node.id] = node
      node.parent_id = parent_id
      node.leaf = !(node.sub? && node.sub.length > 0)

      if parent_id != null
        path_prefix = nodes_by_id[parent_id].path + ' \\ '
      else
        path_prefix = ''
      node.path = path_prefix + node.name
      if !node.leaf
        prepare_nodes(node.sub, node.id)

  prepare_nodes(root_nodes, null)

  return {
    root_nodes : ->
      root_nodes

    node_by_id : (id) ->
      nodes_by_id[id]
  }
