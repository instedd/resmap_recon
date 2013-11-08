angular.module('RmApiService', [])

.factory 'RmApiService', ($http, $q) ->

  s = {
    fields: (collection_id) ->
      s.get("collections/#{collection_id}/fields/mapping.json", {cache: true}).then (data) ->
        data.data

    get: (route) ->
      $http.get s.url(route)

    post: (route, data) ->
      $http.post s.url(route), data


    url: (route) ->
      "/rm/" + route
  }

  s
