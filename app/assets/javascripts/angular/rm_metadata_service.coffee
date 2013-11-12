angular.module('RmMetadataService', ['RmApiService'])

.factory 'RmMetadataService', ($http, RmApiService) ->

  label_for_property: (collection_id, property) ->
    RmApiService.fields(collection_id).then (result) ->
      fields = result
      label = ''
      for field in fields
        label = field.name if field.code == property
      label

  input_type: (collection_id, model) ->
    RmApiService.fields(collection_id, model).then (result) ->
      fields = result
      type = ''
      for field in fields
        type = field.kind if field.code == model
      type

  hierarchy: (collection_id, field_id) ->
    RmApiService.hierarchy(collection_id, field_id)
    #.then (result) ->
    #  result
