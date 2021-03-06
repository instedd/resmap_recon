angular.module('LocationInput', [])

.directive 'locationEdit', ($templateCache, $compile, $rootElement) ->
  restrict: 'A',
  scope:
    latitude: '='
    longitude: '='
    editable: '='
  link: (scope, elem, attrs) ->

    content = $('<div>')
    popoverTemplate = $templateCache.get('location_edit_popover.html')
    $compile(popoverTemplate)(scope).appendTo(content)

    elem.dompopover({
      placement: 'bottom',
      domcontent: content,
      container: $rootElement[0]
    })

    scope.$on 'hide', ->
      elem.dompopover('hide')

    # initialize content behavior
    mapOptions = {
      center: new google.maps.LatLng(0, 0),
      zoom: 14,
      mapTypeId: google.maps.MapTypeId.ROADMAP
      streetViewControl: false,
      overviewMapControl: false,
      rotateControl: false,
      mapTypeControl: false,
      panControl: false,
      zoomControl: true,
      zoomControlOptions: {
        style: google.maps.ZoomControlStyle.SMALL
      },
      scaleControl: false,
    }

    $rootElement.append($('<div style="visibility: hidden;"/>').append(content))
    map = new google.maps.Map($('.map', content)[0], mapOptions);

    marker = null
    changing_scope_localy = false
    scope.is_editable = (if scope.editable? then scope.editable else true)

    update_scope_locally = (latLng) ->
      changing_scope_localy = true
      scope.latitude = latLng.lat()
      scope.longitude = latLng.lng()
      scope.$apply();
      changing_scope_localy = false

    create_or_move_location_marker = ->
      if marker == null
        marker = new google.maps.Marker({
            position: new google.maps.LatLng(scope.latitude, scope.longitude),
            map: map,
            draggable: scope.is_editable,
        })

        google.maps.event.addListener marker, 'dragend', ->
          update_scope_locally(marker.getPosition())
      else
        marker.setPosition(new google.maps.LatLng(scope.latitude, scope.longitude))

    if scope.is_editable
      google.maps.event.addListener map, 'dblclick', (e) ->
        update_scope_locally(e.latLng)
        create_or_move_location_marker()

    scope.$watch "'' + latitude + ';' + longitude", ->
      return if changing_scope_localy

      if !scope.latitude || !scope.longitude
        if marker != null
          marker.setMap(null)
          marker = null
        return
      else
        create_or_move_location_marker()

        if map.getBounds()? && !map.getBounds().contains(marker.getPosition())
          map.setCenter(marker.getPosition())



