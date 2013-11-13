angular.module('PendingList', ['RmHierarchyService'])

.controller 'PendingListCtrl', ($scope, $http, RmHierarchyService) ->
  NodeService = RmHierarchyService.for($scope.collection_id, $scope.hierarchy_field_id)
  $scope.list = []
  for code, count of $scope.pending_list
    node = NodeService.node_by_id(code)
    node.count = count
    $scope.list.push(node)

  $scope.choose = (node) ->
    $scope.$emit('tree-node-chosen', node)
