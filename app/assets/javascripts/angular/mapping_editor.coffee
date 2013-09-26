angular.module('MappingEditor',[])

.controller 'MappingEditorCtrl', ($scope, $http) ->

  $scope.mapping = for e in $scope.mapping_hash
    {
      source_value: e.source_value,
      source_count: e.source_count,
      target_value: e.target_value,
      editing: false
    }

  $scope.$on 'edit-mapping-entry', (e, entry) ->
    $scope.selected_entry.editing = false if $scope.selected_entry?

    entry.editing = true
    $scope.selected_entry = entry

    $scope.$broadcast('tree-node-open', entry.target_value)

  $scope.$on 'tree-node-chosed', (e, node) ->
    return unless $scope.selected_entry?.editing
    $scope.selected_entry.target_value = node.id

    data = { entry: _.merge({source_property: $scope.source_property}, $scope.selected_entry) }
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/update_mapping_entry", data)

.controller 'MappingEntryCtrl', ($scope) ->
  $scope.edit = ->
    $scope.$emit('edit-mapping-entry', $scope.mapping_entry)
