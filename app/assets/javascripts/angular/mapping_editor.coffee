angular.module('MappingEditor',[])

.controller 'MappingEditorCtrl', ($scope, $rootScope) ->

  $scope.mapping = for source_value, target_value of $scope.mapping_hash
    {
      source_value: source_value,
      target_value: target_value,
      editing: false
    }

  $scope.$on 'edit-mapping-entry', (e, entry) ->
    $scope.selected_entry.editing = false if $scope.selected_entry?

    entry.editing = true
    $scope.selected_entry = entry

    $rootScope.$broadcast('tree-node-open', entry.target_value)

  $scope.$on 'tree-node-chosed', (e, node) ->
    return unless $scope.selected_entry?.editing
    $scope.selected_entry.target_value = node.id

.controller 'MappingEntryCtrl', ($scope, $rootScope) ->
  $scope.edit = ->
    $rootScope.$broadcast('edit-mapping-entry', $scope.mapping_entry)
