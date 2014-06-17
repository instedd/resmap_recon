angular.module('RmMetadataService', ['RmApiService'])

.factory 'RmMetadataService', ($http, RmApiService) ->


  s = {
    fields: (collection_id) ->
      RmApiService.get("en/collections/#{collection_id}/fields/mapping.json", {cache: true})

    label_for_property: (collection_id, property) ->
      s.fields(collection_id).then (result) ->
        fields = result.data
        label = ''
        for field in fields
          label = field.name if field.code == property
        label

    input_type: (collection_id, model) ->
      s.fields(collection_id, model).then (result) ->
        fields = result.data
        type = ''
        for field in fields
          type = field.kind if field.code == model
        type

    hierarchy: (collection_id, field_id) ->
      RmApiService.get("en/collections/#{collection_id}/fields/#{field_id}").then (response) ->
        response.data.config.hierarchy
  }

  s
