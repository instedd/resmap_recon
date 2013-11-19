angular.module('RmApiService', [])

.factory 'RmApiService', ($http, $q) ->

  s = {

    get: (route, params) ->
      $http.get s.url(route, params)

    post: (route, data) ->
      $http.post s.url(route), data


    url: (route, params) ->
      if /^http:|^https:|^\/rm\//.test(route)
        res = route
      else
        res = "/rm/" + route

      if params?
        res += '?' + $.param(params)

      res
  }

  s
