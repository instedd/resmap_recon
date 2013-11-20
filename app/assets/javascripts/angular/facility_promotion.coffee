angular.module('FacilityPromotion',['RmApiService'])

.controller 'FacilityPromotionCtrl', ($scope, $http, RmApiService) ->

  $scope.sites = []
  $scope.processed = 0
  $scope.failed = 0
  $scope.working = false
  $scope.done = false
  $scope.can_start = false

  # grab site information
  # and go to last page
  # since the processing will be removing sites from this "list"
  RmApiService.get($scope.sites_to_promote_url).success (data) ->
    $scope.sites = data.sites
    $scope.count = data.count
    $scope.next_url = null

    # go to last page
    if data.nextPage?
      # HACK. asume there is no page=
      RmApiService.get($scope.sites_to_promote_url + "&page=" + data.totalPages).success (data) ->
        $scope.sites = data.sites
        $scope.next_url = data.previousPage
        $scope.can_start = true
    else
      $scope.can_start = true


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
      $scope.next_url = data.previousPage
      $scope.promote_next_site()

  $scope.$watch 'processed', () ->
    $scope.processed_percentage = "#{$scope.processed * 100 / $scope.count}%"
    if $scope.processed == $scope.count
      $scope.working = false
      $scope.done = true
