angular.module('FacilityPromotion',['RmApiService'])

.controller 'FacilityPromotionCtrl', ($scope, $http, RmApiService) ->

  $scope.processed = 0
  $scope.failed = 0
  $scope.working = false
  $scope.done = false
  $scope.can_start = true
  $scope.promoted_properties = {}
  $scope.count = $scope.sites_to_promote_ids.length

  $scope.start = ->
    $scope.working = true
    $scope.promote_properties()

  $scope.promote_next_site = (i) ->
    for site_id in $scope.sites_to_promote_ids
      $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/promote_site", {site_id: site_id}).success (data) ->
        $scope.processed += 1
        $scope.failed += 1 if data.status == 'fail'

  $scope.promote_properties = ->
    props_to_promote = Object.keys $scope.promoted_properties
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/promote_properties", {properties_to_promote: props_to_promote}).success (data) ->
      $scope.promote_next_site()

  $scope.$watch 'processed', () ->
    $scope.processed_percentage = "#{$scope.processed * 100 / $scope.sites_to_promote_ids.length}%"
    if $scope.processed == $scope.sites_to_promote_ids.length
      $scope.working = false
      $scope.done = true
