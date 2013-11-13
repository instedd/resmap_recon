angular.module('RmApiService', [])

.factory 'RmApiService', ($http, $q) ->

  s = {

    get: (route) ->
      $http.get s.url(route)

    post: (route, data) ->
      $http.post s.url(route), data


    url: (route) ->
      "/rm/" + route
  }

  s
