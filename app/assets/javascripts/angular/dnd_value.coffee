value_dragged = null

angular.module('DndValue',[])

.directive 'dndSource', ($document, $parse) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    elem.attr('draggable', true)
    elem.addClass('dnd-source')

    dndSourceGet = $parse(attrs.dndSource)

    targets = null

    elem[0].addEventListener 'dragstart', ->
      targets = $document.find('.dnd-target')
      targets.addClass('target-highlight')
      value_dragged = dndSourceGet(scope)
    , false

    elem[0].addEventListener 'dragend', ->
      targets.removeClass('target-highlight')
    , false

.directive 'dndTarget', ($document, $parse) ->
  restrict: 'A',
  link: (scope, elem, attrs) ->
    elem.addClass('dnd-target')
    elem.attr('draggable', true)

    dndTargetGet = $parse(attrs.dndTarget)
    dndTargetSet = dndTargetGet.assign

    elem[0].addEventListener 'dragover', (e) ->
      e.preventDefault()
    , false

    elem[0].addEventListener 'drop', (e) ->
      dndTargetSet(scope, value_dragged)
      scope.$apply()
      value_dragged = null
      e.preventDefault()
    , false
