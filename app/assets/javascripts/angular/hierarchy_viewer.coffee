angular.module('HierarchyViewer', ['RmHierarchyService'])

.controller 'HierarchyTreeCtrl', ($scope, RmHierarchyService) ->
  NodeService = RmHierarchyService.for($scope.collectionId, $scope.fieldId)
  $scope.nodes = NodeService.roots()

  NodeService.on_load ->
    add_counts = (node, count) ->
      node.count = (node.count || 0) + count
      add_counts node.parent, count if node.parent

    for node_id, count of $scope.pendingList
      node = NodeService.node_by_id(node_id)
      add_counts node, count

    $scope.choose($scope.nodes[0])

  $scope.toggle = (e, node) ->
    node.expanded = not node.expanded
    e.stopPropagation()

  $scope._set_chosen_node = (node) ->
    $scope.chosen_node = node

  $scope.choose = (node) ->
    $scope._set_chosen_node(node)
    $scope.select_node(node.id)
    $scope.$emit('tree-node-chosen', node)

  make_node_visible = (node_id) ->
    if node_id == null
      $scope._set_chosen_node(null)
      return

    # close top level nodes
    for node in $scope.nodes
      node.expanded = false

    n_id = node_id
    while n_id
      n = NodeService.node_by_id(n_id)
      n_id = n.parent_id
      # close siblings
      if n_id
        parent = NodeService.node_by_id(n_id)
        for sibling in parent.sub
          sibling.expanded = false

      n.expanded = true

    $scope._set_chosen_node(NodeService.node_by_id(node_id))

  $scope.$on 'tree-node-open', (e, node_id) ->
    make_node_visible(node_id)

  $scope.$on 'site-removed', (e, node_id) ->
    n_id = node_id
    while n_id != null && n_id != undefined
      node = NodeService.node_by_id(n_id)
      node.count -= 1
      n_id = node.parent_id

  node_id_changed = ->
    make_node_visible($scope.nodeId)

  $scope.$watch 'nodeId', node_id_changed
