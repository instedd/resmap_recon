angular.module('PaginatedGrid', [])

.directive 'mflGrid', () ->
	restrict: 'E'
	scope:
		dataSource: '=mflDataSource'
	templateUrl: 'paginated_grid.html'
	link: (scope, elem, attrs) ->
		last_page = (total_count) ->
			(Math.floor(total_count / 5)) + (if total_count % 5 > 0 then 1 else 0)

		page_context = (current_page, last_page) ->
			(i for i in [(Math.max(1, current_page - 10))..(Math.min(current_page + 10, last_page))])

		refresh = (data, oldData) ->
			if data?.loaded
				scope.loading = false

			scope.current_page = data.current_page
			scope.last_page = last_page(data.total_count)
			scope.pages = page_context(scope.current_page, scope.last_page)

		scope.loading = true

		scope.$watch 'dataSource', refresh, true 

