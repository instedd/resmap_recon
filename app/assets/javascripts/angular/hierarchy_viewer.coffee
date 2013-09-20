angular.module('HierarchyViewer', [])

.controller 'HierarchyTreeCtrl', ($scope) ->

  # [{"id"=>"A", "name"=>"A", "sub"=>[{"id"=>"A2", "name"=>"A2"}, {"id"=>"A1", "name"=>"A1"}]}, {"id"=>"B", "name"=>"B", "sub"=>[{"id"=>"B2", "name"=>"B2"}, {"id"=>"B1", "name"=>"B1"}]}]
  $scope.nodes = $scope.hierarchy

  prepare_nodes = (nodes) ->
    for node in nodes
      node.leaf = !(node.sub? && node.sub.length > 0)
      if !node.leaf
        prepare_nodes(node.sub)
  prepare_nodes($scope.nodes)

  $scope.toggle = (node) ->
    node.expanded = not node.expanded

