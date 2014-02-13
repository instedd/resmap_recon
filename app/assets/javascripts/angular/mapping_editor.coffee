angular.module('MappingEditor',['HierarchySelection', 'RmHierarchyService'])

.controller 'MappingEditorCtrl', ($scope, $http, RmHierarchyService) ->
  $scope.mapping_property_loading = false

  $scope.fields = $scope.source_field_options

  node_service = RmHierarchyService.for_hierarchy($scope.hierarchy)

  $scope.compute_hierarchy_levels = (hierarchy, depth = 0, levels = []) ->
    level_options = []

    for obj in hierarchy
      if depth == 0
        level_options.push kind: 'Fixed value', id: obj.id, name: obj.name
      if levels.length == depth
        levels.push name: obj.name, id: obj.id, options: level_options
      if obj.sub
        $scope.compute_hierarchy_levels obj.sub, depth + 1, levels

    for field_option in $scope.source_field_options
      level_options.push kind: 'Source field', name: field_option.name, id: field_option.id

    levels

  $scope.remove_fixed_values = (level) ->
    level.options = level.options.filter (opt) -> opt.kind != 'Fixed value'

  $scope.recompute_hierarchy_levels = (depth) ->
    if $scope.hierarchy_levels[depth].option.kind == 'Fixed value'
      next_level = $scope.hierarchy_levels[depth + 1]
      if next_level
        node = node_service.node_by_id($scope.hierarchy_levels[depth].option.id)

        $scope.remove_fixed_values(next_level)

        fixed_values = []
        for obj in node.sub
          fixed_values.push kind: 'Fixed value', id: obj.id, name: obj.name
        next_level.options.splice 0, 0, fixed_values...
    else
      depth += 1
      while depth < $scope.hierarchy_levels.length
        $scope.remove_fixed_values($scope.hierarchy_levels[depth])
        depth += 1

  $scope.hierarchy_levels = $scope.compute_hierarchy_levels($scope.hierarchy)

  # $scope.calculate_progress = ->
  #   just_classified = $scope.add_source_values(_.filter($scope.unclassified_mapping, (e)-> e.target_value != null))
  #   classified_count = already_classified + just_classified
  #   $scope.percentage_classified = classified_count * 100 / all_count


  # $scope.calculate_progress()

  $scope.process_automapping = ->
    data = {chosen_fields: [], corrections: $scope.error_tree}
    i = 0
    for level in $scope.hierarchy_levels
      data.chosen_fields[i] = {kind: level.option.kind, name: level.option.name, id: level.option.id} if level.option
      i += 1
    $scope.loading_error_tree = true
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/process_automapping", data)
      .success (data) ->
        $scope.error_tree = data
        $scope.loading_error_tree = false


