angular.module('RmApiService', [])

.factory 'RmApiService', ($http, $q) ->

  s = {
    hierarchy: (collection_id, field_id) ->
      s.get("collections/#{collection_id}/fields/#{field_id}").then (response) ->
        response.data.config.hierarchy

    fields: (collection_id) ->
      s.get("collections/#{collection_id}/fields/mapping.json", {cache: true}).then (response) ->
        response.data

    get: (route) ->
      $http.get s.url(route)

    post: (route, data) ->
      $http.post s.url(route), data


    url: (route) ->
      "/rm/" + route
  }

  s
