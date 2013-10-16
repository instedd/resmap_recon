elem_dragged = null

angular.module('Value',[])

.directive 'value', ($document) ->
  restrict: 'C'
  link: (scope, elem, attrs) ->
    elem.attr('draggable', true)

    targets = null

    elem[0].addEventListener 'dragstart', ->
      targets = $document.find('.target')
      targets.addClass('target-highlight')
      elem_dragged = elem
    , false

    elem[0].addEventListener 'dragend', ->
      targets.removeClass('target-highlight')
    , false

.directive 'target', ($document) ->
  restrict: 'A',
  # scope: {
  #   target: '='
  # }
  link: (scope, elem, attrs) ->
    console.log(attrs)
    elem.addClass('target')
    elem.attr('draggable', true)

    elem[0].addEventListener 'dragover', (e) ->
      e.preventDefault()
    , false

    elem[0].addEventListener 'drop', (e) ->
      scope.$eval("#{attrs.target} = '#{elem_dragged.text()}'")
      scope.$apply()
      elem_dragged = null
      e.preventDefault()
    , false
