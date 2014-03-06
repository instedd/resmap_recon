angular.module('PaginatedGrid', [])

.directive 'mflGrid', () ->
	restrict: 'E'
	scope:
		dataSource: '=mflDataSource'
	templateUrl: 'paginated_grid.html'
	link: (scope, elem, attrs) ->
		switch_off_loading = (newValue, oldValue) ->
			if newValue?.loaded
				scope.loading = false

		scope.loading = true
		
		scope.$watch 'dataSource', switch_off_loading, true 

