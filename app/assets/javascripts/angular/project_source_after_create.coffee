angular.module('ProjectSourceAfterCreate', [])

.controller 'AfterCreateCtrl', ($scope, $http, $window, $timeout) ->
  $scope.status_check_base = 2000
  $scope.status_check_attempts = 0

  $scope.identifier_column = $scope.columns_spec[0]
  $scope.import_disabled = true

  $scope.redirect_in = 5
  $scope.redirect_url = "/projects/#{$scope.project_id}/sources/#{$scope.source_id}/source_list_details"

  $scope.$watch 'identifier_column', ->
    $scope.valid_columns_spec = true
    $scope.valid_columns_loading = true
    $scope.import_disabled = true

    $scope.final_columns_spec = _.cloneDeep($scope.columns_spec)
    # reset resmap initial identifier guess
    for cs in $scope.final_columns_spec
      cs.kind = 'text' if cs.kind == 'identifier'
    # set selected columns as identifier
    id_col = _.find($scope.final_columns_spec, {header: $scope.identifier_column.header})
    id_col.kind = 'identifier'

    params = { columns_spec: $scope.final_columns_spec }
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_id}/import_wizard/validate", params)
      .success (data) ->
        $scope.valid_columns_spec = data.valid
        $scope.validation_errors = data.errors
        $scope.valid_columns_loading = false
        $scope.import_disabled = !$scope.valid_columns_spec

  $scope.import = ->
    $scope.importing = true

    params = { columns_spec: $scope.final_columns_spec }
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.source_id}/import_wizard/start", params)
      .success ->
        $scope._check_status()

  $scope._check_status = ->
    $http.get("/projects/#{$scope.project_id}/sources/#{$scope.source_id}/import_wizard/status")
      .success (data) ->
        $scope.importing = data.status != 'finished'
        $scope.status_finished = data.status == 'finished'

        if $scope.status_finished
          $scope.status_check_attempts = 0 
        else
          $scope.status_check_attempts = $scope.status_check_attempts + 1

        if $scope.importing
          $timeout ->
            $scope._check_status()
            $scope.$apply()
          , Math.min($scope.status_check_base * (2 ^ $scope.status_check_attempts), 30000)
        else
          $timeout ->
            $window.location.href = $scope.redirect_url
          , $scope.redirect_in * 1000


