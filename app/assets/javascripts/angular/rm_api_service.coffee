angular.module('RmApiService', [])

.factory 'RmApiService', ($http) ->

  label_for_property: (collection_id, property) ->
    console.log 'api'
    metadata = metadata()
    for field in metadata["fields"]
      label = field.name if field.code == property
    label

  metadata: (collection_id) ->
    get("collections/#{collection_id}/fields.json").success (data) ->
      return data

  get: (route) ->
    $http.get url(route)

  post: (route, data) ->
    $http.post url(route), data


  url: (route) ->
    "http://localhost:3000/rm/" + route
