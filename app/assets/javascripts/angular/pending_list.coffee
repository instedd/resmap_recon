angular.module('PendingList', ['HierarchyService'])

.controller 'PendingListCtrl', ($scope, $http, HierarchyService) ->

  $scope.list = []
  for code,count of $scope.pending_list
    node = HierarchyService.node_by_id(code)
    node.count = count
    $scope.list.push(node)

  $scope.choose = (node) ->
    $scope.$emit('tree-node-chosen', node)
