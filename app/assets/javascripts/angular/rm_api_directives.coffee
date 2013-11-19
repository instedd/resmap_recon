angular.module("RmApiDirectives", ['RmMetadataService'])

.directive "rmLabel", ($parse, RmMetadataService) ->
  restrict: 'E',
  templateUrl: 'rm_label_template.html',
  link: (scope, elem, attrs) ->
    codeGet = $parse(attrs.code)
    code = codeGet(scope) || attrs.code
    scope.label = RmMetadataService.label_for_property(scope.collection_id, code)

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

.directive "rmPager", () ->
  restrict: 'E'
  templateUrl: 'rm_pager_template.html',
  controller: ($scope, $attrs, $parse, RmApiService) ->
    ngModelGet = $parse($attrs.ngModel)
    ngModelSet = ngModelGet.assign

    ngLoadingModelGet = $parse($attrs.ngLoadingModel)
    ngLoadingModelSet = ngLoadingModelGet.assign

    load_sites_from_url = (url) ->
      ngModelSet($scope, null)
      $scope.$emit 'rm-pager-loading'
      ngLoadingModelSet($scope, true)
      RmApiService.get(url).success (data) ->
        ngModelSet($scope, data)
        $scope.$emit 'rm-pager-loaded'
        ngLoadingModelSet($scope, false)

    $scope.$on 'rm-pager-load-sites', (e, url) ->
      load_sites_from_url(url)

    $scope.go_to_next_page = ->
      if $scope.has_next_page
        load_sites_from_url($scope.page_data.nextPage)

    $scope.go_to_previous_page = ->
      if $scope.has_previous_page
        load_sites_from_url($scope.page_data.previousPage)

    $scope.$watch "#{$attrs.ngModel} | json", ->
      page_data = ngModelGet($scope)
      if page_data?
        $scope.has_next_page = page_data.nextPage?
        $scope.has_previous_page = page_data.previousPage?
      else
        $scope.has_next_page = false
        $scope.has_previous_page = false
