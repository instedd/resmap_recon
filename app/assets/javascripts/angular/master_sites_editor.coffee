angular.module('MasterSitesEditor', ['RmHierarchyService', 'RmApiService'])

.controller 'MasterSitesEditorCtrl', ($scope, $http, RmApiService) ->
  $scope.page_data = null
  $scope.search = ''
  $scope.has_previous_page = false
  $scope.has_next_page = false

  load_sites = ->
    params = {page_size: 20}
    if !_.isEmpty($scope.search)
      params.search = $scope.search

    $scope.$broadcast 'rm-pager-load-sites', RmApiService.url("api/collections/#{$scope.collection_id}.json", params)

  $scope.$watch 'search', _.throttle(load_sites, 200)

.controller 'MasterSiteRow', ($scope, $rootScope, RmHierarchyService) ->
  NodeService = RmHierarchyService.for($scope.collection_id, $scope.hierarchy_field_id)
  $scope.$watch "site.properties.#{$scope.hierarchy_target_field_code}", ->
    node = NodeService.node_by_id($scope.site.properties[$scope.hierarchy_target_field_code])
    $scope.site_hierarchy_node = node

  $scope.edit = ->
    $rootScope.$broadcast('edit-master-site', $scope.site)

.controller 'MasterSiteEditor', ($scope, $http, RmHierarchyService) ->
  original_target_site = null
  modal_editor = $('#MasterSiteEditor')
  skip_modal_hide = false

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
    skip_modal_hide = true
    modal_editor.modal('hide')
    $scope.$broadcast('hide')

  modal_editor.on 'hide', ->
    unless skip_modal_hide
      $scope.cancel()

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
