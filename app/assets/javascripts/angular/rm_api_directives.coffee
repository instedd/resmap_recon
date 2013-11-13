angular.module("RmApiDirectives", ['RmMetadataService'])

.directive "rmLabel", ($parse, RmMetadataService) ->
  restrict: 'E',
  templateUrl: 'rm_label_template.html',
  link: (scope, elem, attrs) ->
    codeGet = $parse(attrs.code)
    scope.label = RmMetadataService.label_for_property(scope.collection_id, codeGet(scope))

.directive "rmCollectionContext", ($parse) ->
  restrict: 'E',
  transclude: true,
  template: "<div ng-transclude></div>"
  compile: ->
    pre: (scope, elem, attrs) ->
      idGet = $parse(attrs.id)
      scope.collection_id = parseInt(idGet(scope))

.directive "rmReadOnlyInput", ($parse, RmMetadataService) ->
  restrict: 'E',
  templateUrl: 'rm_read_only_input_template.html',
  link: (scope, elem, attrs) ->
    modelGet = $parse(attrs.model)
    # split on '.' to search for field code?
    scope.input_type = RmMetadataService.input_type(scope.collection_id, modelGet(scope))

.directive "rmHierarchyTree", ($parse, RmMetadataService) ->
  restrict: 'E',
  templateUrl: 'rm_hierarchy_tree.html'
  compile: ->
    pre: (scope, elem, attrs) ->
      idGet = $parse(attrs.fieldId)
      scope.hierarchy_field_id = parseInt(idGet(scope))
