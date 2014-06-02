angular.module('PaginatedGrid', [])

.directive 'mflGrid', () ->
	restrict: 'E'
	scope:
		dataSource: '=mflDataSource',
		page_changed: '&mflPageChanged'
		selection_changed: '&mflSelectionChanged'
		multiple_selection: '=mflMultipleSelection'
	templateUrl: 'paginated_grid.html'
	link: (scope, elem, attrs) ->
		last_page = (total_count) ->
			(Math.floor(total_count / 5)) + (if total_count % 5 > 0 then 1 else 0)

		page_context = (current_page, last_page) ->
			(i for i in [(Math.max(1, current_page - 10))..(Math.min(current_page + 10, last_page))])

		refresh = (data, oldData) ->
			return unless data
			if data?.loaded
				scope.loading = false

			scope.current_page = parseInt(data.current_page)
			scope.last_page = last_page(data.total_count)
			scope.pages = page_context(scope.current_page, scope.last_page)
			scope.last_page_in_context = scope.pages[scope.pages.length - 1]

		scope.change_page = (new_page) ->
			scope.page_changed(new_page: new_page) unless new_page == scope.current_page

		scope.previous_page = () ->
			scope.change_page(scope.current_page - 1) unless scope.current_page == 1

		scope.next_page = () ->
			scope.change_page(scope.current_page + 1) unless scope.current_page == scope.last_page

		scope.change_item = (item) ->
			if scope.multiple_selection
				if scope.selected_items_ids[item.id]
					scope.selected_items[item.id] = item
				else
					delete scope.selected_items[item.id]
				selection = (item for _, item of scope.selected_items)
				scope.selection_changed(selected_items: selection)
			else
				scope.selected_items = {}
				scope.selected_items_ids = {}
				scope.selected_items[item.id] = item
				scope.selected_items_ids[item.id] = true
				scope.selection_changed(selected_items: [item])

		scope.loading = true
		scope.selected_items = {}
		scope.selected_items_ids = {}

		scope.$on 'clear-selection', () ->
			scope.selected_items = {}
			scope.selected_items_ids = {}
			scope.selection_changed(selected_items: [])


		scope.$watch 'dataSource', refresh, true
