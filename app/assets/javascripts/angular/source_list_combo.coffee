angular.module('SourceListCombo', [])

.directive 'mflSourceListCombo', () ->
	restrict: 'E'
	scope:
		source_lists: '=mflSourceLists',
		selection_changed: '&mflSelectionChanged'
	templateUrl: 'source_list_combo.html'
	link: (scope, elem, attrs) ->
		refresh = (new_value, old_value) ->
			scope.selected_item = new_value[0] if new_value?.length > 0

		item_selected = (new_value, old_value) ->
			scope.selection_changed(new_selected_source_list: new_value) if new_value != old_value

		scope.selected_item = null

		scope.$watch 'source_lists', refresh, true
		scope.$watch 'selected_item', item_selected

