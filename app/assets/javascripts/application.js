// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require lodash
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require dompopover
//= require spin
//= require ladda
//= require angular
//= require_tree ./angular

angular.module('ProjectSourceAfterCreateApp', ['Rails','ProjectSourceAfterCreate', 'Ladda']);
angular.module('MappingEditorApp', ['Rails','MappingEditor', 'HierarchyViewer', 'RmApiDirectives']);
angular.module('CurationApp', ['Rails','DndValue','Curation', 'HierarchyViewer', 'LocationInput', 'Ladda', 'PendingList', 'RmApiDirectives', 'PaginatedGrid', 'SourceListCombo']);
angular.module('MasterSitesEditorApp', ['Rails','DndValue','MasterSitesEditor', 'HierarchyViewer', 'LocationInput', 'RmApiDirectives', 'HierarchyInput']);
angular.module('HierarchySelectionApp', ['Rails','HierarchySelection']);
angular.module('FacilityPromotionApp', ['Rails', 'FacilityPromotion', 'RmApiDirectives']);

$(function(){
  Ladda.bind('.ladda');
});
