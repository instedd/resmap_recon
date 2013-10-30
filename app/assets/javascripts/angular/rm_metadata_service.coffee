angular.module('RmMetadataService', ['RmApiService'])

.factory 'RmMetadataService', ($http, RmApiService) ->

  label_for_property: (property) ->
    console.log 'metadata service'
    RmApiService.label_for_property($scope.collection_id, property)
