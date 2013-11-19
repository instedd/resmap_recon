angular.module('FacilityPromotion',['RmApiService'])

.controller 'FacilityPromotionCtrl', ($scope, $http, RmApiService) ->

  $scope.sites = []
  $scope.processed = 0
  $scope.failed = 0
  $scope.working = false

  RmApiService.get("api/collections/#{$scope.collection_id}.json").success (data) ->
    $scope.sites = data.sites
    $scope.count = data.count
    $scope.next_url = data.nextPage

  $scope.start = ->
    $scope.working = true
    $scope.promote_next_site()

  $scope.promote_next_site = ->
    site = _.first $scope.sites
    if site
      $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_list_id}/promote_site", {site_id: site.id}).success (data) ->
        $scope.processed += 1
        $scope.failed += 1 if data.status == 'fail'
        $scope.sites = _.rest($scope.sites)
        if $scope.sites.length > 0
          $scope.promote_next_site()
        else
          $scope.load_more_sites() if $scope.next_url

  $scope.load_more_sites = ->
    $http.get($scope.next_url).success (data) ->
      $scope.sites = data.sites
      $scope.next_url = data.nextUrl
      $scope.promote_next_site()

  $scope.$watch 'processed', () ->
    $scope.processed_percentage = "#{$scope.processed * 100 / $scope.count}%"
    if $scope.processed == $scope.count
      $scope.working = false
