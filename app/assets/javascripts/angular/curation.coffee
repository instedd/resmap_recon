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
    $scope.sites.splice($scope.sites.indexOf(site), 1)

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
