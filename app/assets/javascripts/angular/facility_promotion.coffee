angular.module('FacilityPromotion',['RmApiService'])

.controller 'FacilityPromotionCtrl', ($scope, $http, RmApiService) ->

  $scope.sites = []
  $scope.promoted = 0
  $scope.working = false

  RmApiService.get("api/collections/#{$scope.collection_id}.json").success (data) ->
    $scope.sites = data.sites
    $scope.count = data.count
    $scope.next_url = data.nextPage

  $scope.start = ->
    $scope.working = true
    $scope.promote()

  $scope.promote = ->
    _.each $scope.sites, (site) ->
      $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/promote_site", {site_id: site.id}).success ->
        $scope.promoted += 1
    if $scope.next_url
      $scope.load_more_sites()

  $scope.load_more_sites = ->
    $http.get($scope.next_url).success (data) ->
      $scope.sites = data.sites
      $scope.next_url = data.nextUrl
      $scope.promote()

  $scope.$watch 'promoted', () ->
    $scope.promoted_percentage = "#{$scope.promoted * 100 / $scope.count}%"
    if $scope.promoted == $scope.count
      $scope.working = false
