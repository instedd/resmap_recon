angular.module('RmMetadataService', ['RmApiService'])

.factory 'RmMetadataService', ($http, RmApiService) ->

  label_for_property: (collection_id, property) ->
    RmApiService.fields(collection_id).then (result) ->
      fields = result
      for field in fields
        label = field.name if field.code == property
      label
