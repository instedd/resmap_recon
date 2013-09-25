angular.module('HierarchyViewer', [])

.controller 'HierarchyTreeCtrl', ($scope) ->

  # [{"id"=>"A", "name"=>"A", "sub"=>[{"id"=>"A2", "name"=>"A2"}, {"id"=>"A1", "name"=>"A1"}]}, {"id"=>"B", "name"=>"B", "sub"=>[{"id"=>"B2", "name"=>"B2"}, {"id"=>"B1", "name"=>"B1"}]}]
  $scope.nodes = $scope.hierarchy
  $scope.nodes_by_id = {}

  prepare_nodes = (nodes, parent_id) ->
    for node in nodes
      $scope.nodes_by_id[node.id] = node
      node.parent_id = parent_id
      node.leaf = !(node.sub? && node.sub.length > 0)
      if !node.leaf
        prepare_nodes(node.sub, node.id)

  prepare_nodes($scope.nodes, null)

  $scope.toggle = (node) ->
    node.expanded = not node.expanded

  $scope._set_choosen_node = (node) ->
    if $scope.choosen_node
      $scope.choosen_node.choosen = false
    $scope.choosen_node = node
    if $scope.choosen_node
      $scope.choosen_node.choosen = true

  $scope.choose = (node) ->
    $scope._set_choosen_node(node)
    $scope.$emit('tree-node-chosed', node)

  $scope.$on 'tree-node-open', (e, node_id) ->
    if node_id == null
      $scope._set_choosen_node(null)
      return

    for node in $scope.nodes
      node.expanded = false

    n_id = node_id
    while n_id != null
      n = $scope.nodes_by_id[n_id]
      n.expanded = true
      n_id = n.parent_id

    $scope._set_choosen_node($scope.nodes_by_id[node_id])
