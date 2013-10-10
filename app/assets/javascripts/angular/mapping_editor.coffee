angular.module('MappingEditor',['HierarchySelection'])

.controller 'MappingEditorCtrl', ($scope, $http) ->

  $scope.mapping_property = $scope.source_field_options.filter((e)->
    e.id == $scope.source_property
  )[0]
  $scope.fields = $scope.source_field_options

  $scope.$watch 'mapping_property', ->
    url = "/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/update_mapping_property"
    if $scope.mapping_property && $scope.mapping_property.id != $scope.source_property
      $http.post(url, {mapping_property_id: $scope.mapping_property.id}).success ->
        location.reload()

  $scope.classified_mapping = []
  $scope.unclassified_mapping = []

  for e in $scope.mapping_hash
    if e.target_value == null
      $scope.unclassified_mapping.push {
        source_value: e.source_value,
        source_count: e.source_count,
        target_value: e.target_value,
      }
    else
      $scope.classified_mapping.push {
        source_value: e.source_value,
        source_count: e.source_count,
        target_value: e.target_value,
      }

  $scope.calculate_progress = ->
    just_classified = _.filter($scope.unclassified_mapping, (e)-> e.target_value != null).length
    classified_count = $scope.classified_mapping.length + just_classified
    $scope.percentage_classified = classified_count * 100 / ($scope.mapping_hash.length)

  $scope.calculate_progress()

  $scope.$on 'edit-mapping-entry', (e, entry) ->
    $scope.selected_entry = entry

    $scope.$broadcast('request-hierarchy-input', entry.target_value)

  $scope.$on 'selected-hierarchy-node', (e, node_id) ->
    $scope.selected_entry.target_value = node_id
    $scope.calculate_progress()

    data = { entry: _.merge({source_property: $scope.source_property}, $scope.selected_entry) }
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/update_mapping_entry", data)

.controller 'MappingEntryCtrl', ($scope) ->
  $scope.edit = ->
    $scope.$emit('edit-mapping-entry', $scope.mapping_entry)

