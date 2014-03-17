angular.module('HierarchyViewer', ['RmHierarchyService'])

.controller 'HierarchyTreeCtrl', ($scope, RmHierarchyService) ->
  field_id = $scope.hierarchy_field_id
  NodeService = RmHierarchyService.for($scope.collection_id, field_id)
  $scope.nodes = NodeService.roots()

  NodeService.on_load ->
    add_counts = (node, count) ->
      node.count = (node.count || 0) + count
      add_counts node.parent, count if node.parent

    for node_id, count of $scope.pending_list
      node = NodeService.node_by_id(node_id)
      add_counts node, count

    $scope.choose($scope.nodes[0])

  $scope.toggle = (node) ->
    node.expanded = not node.expanded

  $scope._set_chosen_node = (node) ->
    if $scope.chosen_node
      $scope.chosen_node.chosen = false
    $scope.chosen_node = node
    if $scope.chosen_node
      $scope.chosen_node.chosen = true

  $scope.choose = (node) ->
    $scope._set_chosen_node(node)
    $scope.$emit('tree-node-chosen', node)

  $scope.$on 'tree-node-open', (e, node_id) ->
    if node_id == null
      $scope._set_chosen_node(null)
      return

    # close top level nodes
    for node in $scope.nodes
      node.expanded = false

    n_id = node_id
    while n_id != null
      n = NodeService.node_by_id(n_id)
      n_id = n.parent_id
      # close siblings
      if n_id != null
        parent = NodeService.node_by_id(n_id)
        for sibling in parent.sub
          sibling.expanded = false

      n.expanded = true

    $scope._set_chosen_node(NodeService.node_by_id(node_id))
