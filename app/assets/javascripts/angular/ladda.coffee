
angular.module('Ladda', [])

.directive 'laddaLoading', ->
  restrict: 'A',
  link: (scope, elem, attrs) ->
    elem.addClass 'ladda-button'
    elem.attr 'data-style', 'expand-right'
    l = Ladda.create(elem[0])

    scope.$watch attrs.laddaLoading, (newVal) ->
      if newVal?
        if newVal
          l.start()
        else
          l.stop()

