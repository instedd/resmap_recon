angular.module('MappingEditor',['HierarchySelection', 'RmHierarchyService'])

.controller 'MappingEditorCtrl', ($scope, $http, RmHierarchyService) ->
  $scope.mapping_property_loading = false

  $scope.mapping_property = $scope.source_field_options.filter((e)->
    e.id == $scope.source_property
  )[0]
  $scope.fields = $scope.source_field_options

  $scope.$watch 'mapping_property', ->
    url = "/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/update_mapping_property"
    if $scope.mapping_property && $scope.mapping_property.id != $scope.source_property
      $scope.mapping_property_loading = true
      $http.post(url, {mapping_property_id: $scope.mapping_property.id}).success ->
        location.reload()

  $scope.classified_mapping = []
  $scope.unclassified_mapping = []

  all_count = 0
  for e in $scope.mapping_hash
    all_count += e.source_count
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

  already_classified = 0
  for e in $scope.classified_mapping
    already_classified += e.source_count

  node_service = RmHierarchyService.for_hierarchy($scope.hierarchy)

  $scope.compute_hierarchy_levels = (hierarchy, depth = 0, levels = []) ->
    level_options = []

    for obj in hierarchy
      if depth == 0
        level_options.push kind: 'Fixed value', id: obj.id, name: obj.name
      if levels.length == depth
        levels.push name: obj.name, options: level_options
      if obj.sub
        $scope.compute_hierarchy_levels obj.sub, depth + 1, levels

    for field_option in $scope.source_field_options
      level_options.push kind: 'Source field', name: field_option.name

    levels

  $scope.remove_fixed_values = (level) ->
    level.options = level.options.filter (opt) -> opt.kind != 'Fixed value'

  $scope.recompute_hierarchy_levels = (depth) ->
    if $scope.hierarchy_levels[depth].option.kind == 'Fixed value'
      next_level = $scope.hierarchy_levels[depth + 1]
      if next_level
        node = node_service.node_by_id($scope.hierarchy_levels[depth].option.id)

        $scope.remove_fixed_values(next_level)

        for obj in node.sub
          next_level.options.push kind: 'Fixed value', id: obj.id, name: obj.name
    else
      depth += 1
      while depth < $scope.hierarchy_levels.length
        $scope.remove_fixed_values($scope.hierarchy_levels[depth])
        depth += 1

  $scope.hierarchy_levels = $scope.compute_hierarchy_levels($scope.hierarchy)

  $scope.add_source_values = (array) ->
    sum = 0
    for e in array
      sum += e.source_count
    return sum

  $scope.calculate_progress = ->
    just_classified = $scope.add_source_values(_.filter($scope.unclassified_mapping, (e)-> e.target_value != null))
    classified_count = already_classified + just_classified
    $scope.percentage_classified = classified_count * 100 / all_count


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

