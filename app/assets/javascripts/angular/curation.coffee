angular.module('Curation',[])

.controller 'CurationPanel', ($scope, $http) ->

  $scope.selected_node = null
  $scope.sites_loading = false

  $scope.$on 'tree-node-chosed', (e, node) ->
    $scope.selected_node = node
    $scope._load_pending_changes()

  $scope._load_pending_changes = ->
    $scope.sites_loading = true
    $http.get("/projects/#{$scope.project_id}/pending_changes", { params: {target_value: $scope.selected_node.id} })
      .success (data) ->
        $scope.sites = data
        $scope.sites_loading = false

  $scope.$on 'site-dismissed', (e, site) ->
    # remove site from pending
    index = $scope.sites.indexOf(site)
    $scope.sites.splice(index, 1)

    # open next pending site
    next_site_index = Math.min($scope.sites.length - 1, index)
    if next_site_index >= 0
      $scope.$broadcast 'outside-pending-site-selected', $scope.sites[next_site_index]

  $scope.$on 'pending-site-selected', (e, site) ->
    $scope.$broadcast 'outside-pending-site-selected', site

.controller 'PendingSiteCtrl', ($scope, $http) ->
  $scope.selected = false

  $scope.dismiss = ->
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.site.source_list.id}/sites/#{$scope.site.id}/dismiss")
      .success ->
        $scope.$emit('site-dismissed', $scope.site)

  $scope.select = ->
    $scope.selected = true
    $scope.$emit 'pending-site-selected', $scope.site

  $scope.cancel = ->
    $scope.selected = false
    $scope.$emit 'pending-site-selected', null

  $scope.$on 'outside-pending-site-selected', (e, site) ->
    $scope.selected = site == $scope.site

.controller 'SearchSiteCtrl', ($scope, $http) ->
  $scope.search_loading = false
  $scope.search = ''
  $scope.sites = null

  $scope._search_sites = ->
    if _.isEmpty($scope.search)
      $scope.sites = null
    else
      $scope.search_loading = true
      $http.get("/projects/#{$scope.project_id}/master/sites/search", {params: {search: $scope.search}})
        .success (data) ->
          $scope.sites = data
        $scope.search_loading = false

  $scope.$watch 'search', _.throttle($scope._search_sites, 200)

  $scope.select = (site) ->
    $scope.$emit 'site-search-selected', site

  $scope.$on 'site-search-clear', ->
    $scope.search = ''
    $scope._search_sites()

.controller 'ConsolitateSiteCtrl', ($scope, $http) ->
  $scope.target_site = null
  $scope.consolidated_sites = null
  $scope.source_site = null

  $scope.$on 'site-search-selected', (e, site) ->
    $scope._select_target_site(site)

  $scope._select_target_site = (site) ->
    $scope.target_site = site

    $scope.consolidated_sites = null
    $http.get("/projects/#{$scope.project_id}/master/sites/#{$scope.target_site.id}/consolidated_sites")
      .success (data) ->
        $scope.consolidated_sites = data

  $scope.$on 'outside-pending-site-selected', (e, site) ->
    $scope.source_site = site
    return if $scope.source_site == null
    master_site_id = site.properties[$scope.app_master_site_id]
    if master_site_id
      $http.get("/projects/#{$scope.project_id}/master/sites/search", {params: {id: master_site_id}})
        .success (data) ->
          if data.length == 1
            $scope._select_target_site(data[0])

  $scope.go_to_search = ->
    $scope.target_site = null

  $scope.go_to_and_reset_search = ->
    $scope.go_to_search()
    $scope.$broadcast('site-search-clear')

  $scope.consolidate = ->
    params = {
      source_site: {
        id: $scope.source_site.id,
        source_list_id: $scope.source_site.source_list.id
      }
      target_site: $scope.target_site
    }

    $http.post("/projects/#{$scope.project_id}/master/sites/#{$scope.target_site.id}", params)
      .success ->
        $scope.go_to_and_reset_search()
        $scope.$emit('site-dismissed', $scope.source_site)
