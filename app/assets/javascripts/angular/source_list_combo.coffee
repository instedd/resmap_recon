angular.module('SourceListCombo', [])

.directive 'mflSourceListCombo', () ->
	restrict: 'E'
	scope:
		source_lists: '=mflSourceLists',
		selection_changed: '&mflSelectionChanged',
		selected_item: '=mflSelectedItem'
	templateUrl: 'source_list_combo.html'
	link: (scope, elem, attrs) ->

		item_selected = (new_value, old_value) ->
			scope.selection_changed(new_selected_source_list: new_value) if new_value != old_value

		scope.$watch 'selected_item', item_selected

