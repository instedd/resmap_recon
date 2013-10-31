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
  link: (scope, elem, attrs) ->
    idGet = $parse(attrs.id)
    scope.collection_id = parseInt(idGet(scope))
