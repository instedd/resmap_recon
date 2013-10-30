angular.module("RmApiDirectives", ['RmMetadataService'])

.directive "RmLabel", factory = (RmMetadataService) ->
  restrict: 'A',
  templateUrl: "rm_label_template",
  link: (scope, elem, attrs) ->
    console.log('link')
    RmMetadadataService.label_for_property(attrs.code)
