angular.module("RmApiDirectives", ['RmMetadataService'])

.directive "rmLabel", ($parse, RmMetadataService) ->
  restrict: 'E',
  templateUrl: 'rm_label_template.html',
  link: (scope, elem, attrs) ->
    console.log('link')
    codeGet = $parse(attrs.code)
    # scope.label = 'label:' + attrs.code
    scope.label = RmMetadataService.label_for_property(codeGet(scope))
