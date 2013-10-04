angular.module('MasterSitesEditor', ['HierarchyService'])

.controller 'MasterSitesEditorCtrl', ($scope, $http) ->
  $scope.sites = null
  $scope.search = ''

  load_sites = ->
    $scope.sites = null
    $scope.loading = true
    params = {}
    if !_.isEmpty($scope.search)
      params.search = $scope.search
    $http.get("/projects/#{$scope.project_id}/master/sites/search", params: params)
      .success (data) ->
        $scope.sites = data
        $scope.loading = false

  $scope.$watch 'search', _.throttle(load_sites, 200)

.controller 'MasterSiteRow', ($scope, $rootScope, HierarchyService) ->
  $scope.$watch "site.properties.#{$scope.hierarchy_target_field_code}", ->
    node = HierarchyService.node_by_id($scope.site.properties[$scope.hierarchy_target_field_code])
    $scope.site_hierarchy_path = node?.path

  $scope.edit = ->
    $rootScope.$broadcast('edit-master-site', $scope.site)

.controller 'MasterSiteEditor', ($scope, $http, HierarchyService) ->
  original_target_site = null
  modal_editor = $('#MasterSiteEditor')

  $scope.$on 'edit-master-site', (e, site) ->
    original_target_site = site
    $scope.target_site = _.cloneDeep(site)
    modal_editor.modal('show')

    # begin duplicate code consolidated_sites
    $scope.consolidated_sites = null
    return if $scope.target_site.id == null
    $http.get("/projects/#{$scope.project_id}/master/sites/#{$scope.target_site.id}/consolidated_sites")
      .success (data) ->
        $scope.consolidated_sites = data
    # end

  $scope._close = ->
    modal_editor.modal('hide')
    $scope.$broadcast('hide')

  modal_editor.on 'hide', ->
    $scope.$broadcast('hide')
    original_target_site = null

  $scope.save = ->
    params = {
      target_site: $scope.target_site
    }

    $http.post("/projects/#{$scope.project_id}/master/sites/#{$scope.target_site.id}", params)
      .success ->
        _.assign(original_target_site, _.cloneDeep($scope.target_site))
        $scope._close()

  $scope.cancel = ->
    original_target_site = null
    $scope._close()
