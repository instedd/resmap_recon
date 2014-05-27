angular.module('PaginatedGrid', [])

.directive 'mflGrid', () ->
	restrict: 'E'
	scope:
		dataSource: '=mflDataSource',
		page_changed: '&mflPageChanged'
		selection_changed: '&mflSelectionChanged'
	templateUrl: 'paginated_grid.html'
	link: (scope, elem, attrs) ->
		last_page = (total_count) ->
			(Math.floor(total_count / 5)) + (if total_count % 5 > 0 then 1 else 0)

		page_context = (current_page, last_page) ->
			(i for i in [(Math.max(1, current_page - 10))..(Math.min(current_page + 10, last_page))])

		refresh = (data, oldData) ->
			if data?.loaded
				scope.loading = false

			scope.current_page = parseInt(data.current_page)
			scope.last_page = last_page(data.total_count)
			scope.pages = page_context(scope.current_page, scope.last_page)
			scope.last_page_in_context = scope.pages[scope.pages.length - 1]

			if scope.selected_item != 0
				for item in data.items
					if scope.selected_item.id == item.id
						scope.selected_item = item
						break

		item_selected = (new_value, old_value) ->
			scope.selection_changed(new_selected_item: new_value) if new_value != old_value

		scope.change_page = (new_page) ->
			scope.page_changed(new_page: new_page) unless new_page == scope.current_page

		scope.previous_page = () ->
			scope.change_page(scope.current_page - 1) unless scope.current_page == 1

		scope.next_page = () ->
			scope.change_page(scope.current_page + 1) unless scope.current_page == scope.last_page

		scope.loading = true
		scope.selected_item = 0

		scope.$watch 'dataSource', refresh, true
		scope.$watch 'selected_item', item_selected
