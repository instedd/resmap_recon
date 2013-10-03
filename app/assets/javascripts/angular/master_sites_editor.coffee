angular.module('MasterSitesEditor', ['HierarchyService'])

.controller 'MasterSitesEditorCtrl', ($scope, $http) ->

  $scope.sites = null

  $scope.loading = true
  # load all master sites
  $http.get("/projects/#{$scope.project_id}/master/sites/search")
    .success (data) ->
      $scope.sites = data
      $scope.loading = false

.controller 'MasterSiteRow', ($scope, $rootScope, HierarchyService) ->
  $scope.$watch "site.properties.#{$scope.hierarchy_target_field_code}", ->
    node = HierarchyService.node_by_id($scope.site.properties[$scope.hierarchy_target_field_code])
    $scope.site_hierarchy_path = node.path

  $scope.edit = ->
    $rootScope.$broadcast('edit-master-site', $scope.site)

.controller 'MasterSiteEditor', ($scope, $http, HierarchyService) ->
  $scope.$on 'edit-master-site', (e, site) ->
    $scope.target_site = site
    $('#MasterSiteEditor').modal('show')

    # begin duplicate code consolidated_sites
    $scope.consolidated_sites = null
    return if $scope.target_site.id == null
    $http.get("/projects/#{$scope.project_id}/master/sites/#{$scope.target_site.id}/consolidated_sites")
      .success (data) ->
        $scope.consolidated_sites = data
    # end

  $scope.save = ->
    params = {
      target_site: $scope.target_site
    }

    $http.post("/projects/#{$scope.project_id}/master/sites/#{$scope.target_site.id}", params)
      .success ->
        $('#MasterSiteEditor').modal('hide')

  $scope.cancel = ->
    # TODO discard editions
    $('#MasterSiteEditor').modal('hide')
