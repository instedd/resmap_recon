angular.module('Curation',[])

.controller 'CurationPanel', ($scope, $http) ->

  $scope.selected_node = null
  $scope.sites_loading = false

  $scope.$on 'tree-node-chosed', (e, node) ->
    $scope.selected_node = node
    $scope._load_pending_changes()


  $scope._load_pending_changes = ->
    $scope.sites_loading = true
    $http.get("/projects/#{$scope.project_id}/pending_changes")
      .success (data) ->
        $scope.sites = data
        $scope.sites_loading = false

