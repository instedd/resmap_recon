angular.module('MappingEditor',['HierarchySelection', 'RmHierarchyService'])

.controller 'MappingEditorCtrl', ($scope, $http, RmHierarchyService) ->
  $scope.fields = $scope.source_field_options

  node_service = RmHierarchyService.for_hierarchy($scope.hierarchy)

  $scope.compute_hierarchy_levels = (hierarchy, depth = 0, levels = []) ->
    level_options = []

    for obj in hierarchy
      # if depth == 0
      #   level_options.push kind: 'Fixed value', id: obj.id, name: obj.name
      if levels.length == depth
        levels.push name: obj.name, id: obj.id, options: level_options
      if obj.sub
        $scope.compute_hierarchy_levels obj.sub, depth + 1, levels

    for field_option in $scope.source_field_options
      level_options.push kind: 'Source field', name: field_option.name, id: field_option.id

    levels

  # $scope.remove_fixed_values = (level) ->
  #   level.options = level.options.filter (opt) -> opt.kind != 'Fixed value'

  $scope.recompute_hierarchy_levels = (depth) ->
    # if $scope.hierarchy_levels[depth].option.kind == 'Fixed value'
    #   next_level = $scope.hierarchy_levels[depth + 1]
    #   if next_level
    #     node = node_service.node_by_id($scope.hierarchy_levels[depth].option.id)

    #     $scope.remove_fixed_values(next_level)

    #     fixed_values = []
    #     for obj in node.sub
    #       fixed_values.push kind: 'Fixed value', id: obj.id, name: obj.name
    #     next_level.options.splice 0, 0, fixed_values...
    # else
    depth += 1
    while depth < $scope.hierarchy_levels.length
      $scope.remove_fixed_values($scope.hierarchy_levels[depth])
      depth += 1
    check_if_complete()

  $scope.hierarchy_levels = $scope.compute_hierarchy_levels($scope.hierarchy)

  check_if_complete = () ->
    $scope.all_fields_chosen = _.all(_.map $scope.hierarchy_levels, (level) ->
      level.option
    )

  $scope.process_automapping = ->
    # Removing the possibility of corrections for the time being
    # data = {chosen_fields: [], corrections: $scope.error_tree}
    data = {chosen_fields: []}
    i = 0
    for level in $scope.hierarchy_levels
      data.chosen_fields[i] = {kind: level.option.kind, name: level.option.name, id: level.option.id} if level.option
      i += 1
    $scope.loading_error_tree = true
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/process_automapping", data)
      .success (data) ->
        $scope.error_tree = data.error_tree
        $scope.mapped_count = data.count
        $scope.percentage_classified = data.mapping_progress
        $scope.loading_error_tree = false


