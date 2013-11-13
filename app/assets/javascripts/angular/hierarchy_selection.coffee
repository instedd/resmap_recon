angular.module('HierarchySelection', ['RmHierarchyService'])

.controller 'HierarchySelectionCtrl', ($scope, $http, RmHierarchyService) ->
  original_entry = null
  modal_editor = $('#HierarchySelection')

  $scope.$on 'request-hierarchy-input', (e, node_id) ->
    $scope.$broadcast('tree-node-open', node_id)
    modal_editor.modal('show')

  $scope.$on 'tree-node-chosen', (e, node) ->
    $scope.chosen_node_id = node.id

  $scope._close = ->
    modal_editor.modal('hide')

  $scope.ok = ->
    $scope.$emit('selected-hierarchy-node', $scope.chosen_node_id)
    $scope._close()

  $scope.cancel = ->
    $scope._close()
