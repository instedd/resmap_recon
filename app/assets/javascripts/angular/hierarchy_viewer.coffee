angular.module('HierarchyViewer', ['RmMetadataService'])

.controller 'HierarchyTreeCtrl', ($scope, RmMetadataService) ->

  # [{"id"=>"A", "name"=>"A", "sub"=>[{"id"=>"A2", "name"=>"A2"}, {"id"=>"A1", "name"=>"A1"}]}, {"id"=>"B", "name"=>"B", "sub"=>[{"id"=>"B2", "name"=>"B2"}, {"id"=>"B1", "name"=>"B1"}]}]
  field_id = $scope.hierarchy_field_id
  RmMetadataService.hierarchy($scope.collection_id, field_id).then (hierarchy) ->
    $scope.nodes = hierarchy
    prepare_nodes($scope.nodes, null)

  $scope.nodes_by_id = {}

  prepare_nodes = (nodes, parent_id) ->
    for node in nodes
      $scope.nodes_by_id[node.id] = node
      node.parent_id = parent_id
      node.leaf = !(node.sub? && node.sub.length > 0)
      if !node.leaf
        prepare_nodes(node.sub, node.id)


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
    $scope.$emit('tree-node-chosen', node)

  $scope.$on 'tree-node-open', (e, node_id) ->
    if node_id == null
      $scope._set_choosen_node(null)
      return

    # close top level nodes
    for node in $scope.nodes
      node.expanded = false

    n_id = node_id
    while n_id != null
      n = $scope.nodes_by_id[n_id]
      n_id = n.parent_id
      # close siblings
      if n_id != null
        parent = $scope.nodes_by_id[n_id]
        for sibling in parent.sub
          sibling.expanded = false

      n.expanded = true

    $scope._set_choosen_node($scope.nodes_by_id[node_id])
