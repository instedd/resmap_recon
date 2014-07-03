angular.module('HierarchyInput', [])

.directive 'hierarchyInput', ($templateCache, $compile, $rootElement, RmHierarchyService) ->
  restrict: 'E'
  scope:
    nodeId: '='
    collectionId: '='
    fieldId: '='
  templateUrl: 'hierarchy_input.html'
  link: (scope, elem, attrs) ->
    NodeService = RmHierarchyService.for(scope.collectionId, scope.fieldId)

    update_node = ->
      scope.node = NodeService.node_by_id(scope.nodeId)

    scope.$watch 'nodeId', update_node

