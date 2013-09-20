angular.module('MappingEditor',[])

.controller 'MappingEditorCtrl', ($scope) ->

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

.controller 'MappingEntryCtrl', ($scope, $rootScope) ->
  $scope.edit = ->
    $rootScope.$broadcast('edit-mapping-entry', $scope.mapping_entry)
