angular.module('MappingEditor',[])

.controller 'MappingEditorCtrl', ($scope, $http) ->

  $scope.classified_mapping = []
  $scope.unclassified_mapping = []
  for e in $scope.mapping_hash
    if e.target_value == null
      $scope.unclassified_mapping.push {
        source_value: e.source_value,
        source_count: e.source_count,
        target_value: e.target_value,
        editing: false
      }
    else
      $scope.classified_mapping.push {
        source_value: e.source_value,
        source_count: e.source_count,
        target_value: e.target_value,
        editing: false
      }

  $scope.$watch 'classified_mapping', ->
    $scope.percentage_classified = "#{$scope.classified_mapping.length * 100 / ($scope.mapping_hash.length)}%"

  $scope.$on 'edit-mapping-entry', (e, entry) ->
    $scope.selected_entry.editing = false if $scope.selected_entry?

    entry.editing = true
    $scope.selected_entry = entry

    $scope.$broadcast('tree-node-open', entry.target_value)

  $scope.mapping_property = $scope.source_field_options.filter((e)->
    e.id == $scope.source_property
  )[0]
  $scope.fields = $scope.source_field_options

  $scope.$watch 'mapping_property', ->
    url = "/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/update_mapping_property"
    if $scope.mapping_property.id != $scope.source_property
      $http.post(url, {mapping_property_id: $scope.mapping_property.id}).success ->
        location.reload()

  $scope.$on 'tree-node-chosed', (e, node) ->
    return unless $scope.selected_entry?.editing

    $scope.selected_entry.target_value = node.id

    data = { entry: _.merge({source_property: $scope.source_property}, $scope.selected_entry) }
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/update_mapping_entry", data)

.controller 'MappingEntryCtrl', ($scope) ->
  $scope.edit = ->
    $scope.$emit('edit-mapping-entry', $scope.mapping_entry)

