angular.module('Curation',[])

.controller 'CurationPanel', ($scope, $http) ->

  $scope.selected_node = null
  $scope.sites_loading = false
  $scope.next_page_url = null
  $scope.reached_final_page = false
  $scope.source_records_search = null

  $scope.clear_sites = ->
    $scope.sites = {items: [], headers: [], loaded: false}
  $scope.clear_sites()

  # This is to discard old requests if the user searches something and while
  # the search is being performed, she searches something else.
  $scope.pending_changes_seq = 0
  $scope.mfl_sites_seq = 0

  $scope.$on 'tree-node-chosen', (e, node) ->
    $scope.selected_node = node
    $scope._reset_and_load_pending_changes()
    $scope.$broadcast('curation-panel-node-chosen', $scope.selected_node)

  $scope.$on 'search-source-records', (e, search) ->
    if $scope.selected_node
      $scope.source_records_search = search
      $scope.$broadcast 'search-source-records-changed', search
      $scope._reset_and_load_pending_changes()

  $scope._reset_and_load_pending_changes = ->
    $scope.sites.items.splice(0, $scope.sites.items.length)
    $scope.next_page_url = null
    $scope._load_pending_changes()

  $scope._load_pending_changes = ->
    $scope.pending_changes_seq += 1
    seq = $scope.pending_changes_seq

    $scope.$broadcast 'outside-pending-site-selected', null
    $scope.sites_loading = true
    if $scope.next_page_url != null
      page_request = $http.get($scope.next_page_url)
    else
      params = { params: {target_value: $scope.selected_node?.id, search: $scope.source_records_search} }
      page_request = $http.get("/projects/#{$scope.project_id}/pending_changes", params)

    page_request.success (data) ->
      # Check if there's a new request going on
      return if seq != $scope.pending_changes_seq

      $scope.sites.items = $scope.sites.items.concat data.sites
      $scope.next_page_url = data.next_page_url
      $scope.sites.headers = data.headers
      $scope.sites.current_page = data.current_page
      $scope.sites.total_count = data.total_count

      $scope.reached_final_page = data.next_page_url == undefined
      $scope.sites.loaded = true
      $scope.sites_loading = false

  $scope.next_page = ->
    $scope._load_pending_changes()

  $scope.$on 'site-dismissed', (e, site) ->
    # remove site from pending
    index = $scope.sites.items.indexOf(site)
    $scope.sites.items.splice(index, 1)

    # open next pending site
    next_site_index = Math.min($scope.sites.items.length - 1, index)
    if next_site_index >= 0
      $scope.$broadcast 'outside-pending-site-selected', $scope.sites.items[next_site_index]
    else
      $scope.$broadcast 'outside-pending-site-selected', null

  $scope.$on 'pending-site-selected', (e, site) ->
    $scope.$broadcast 'outside-pending-site-selected', site

  $scope._reset_and_load_pending_changes( )

.controller 'PendingSiteCtrl', ($scope, $http) ->
  $scope.selected = false

  $scope.dismiss = ->
    $http.post("/projects/#{$scope.project_id}/sources/#{$scope.site.source_list.id}/sites/#{$scope.site.id}/dismiss")
      .success ->
        $scope.$emit('site-dismissed', $scope.site)

  $scope.select = ->
    $scope.selected = true
    $scope.$emit 'pending-site-selected', $scope.site

  $scope.cancel = ->
    $scope.selected = false
    $scope.$emit 'pending-site-selected', null

  $scope.$on 'outside-pending-site-selected', (e, site) ->
    $scope.selected = site == $scope.site

.controller 'MasterFacilityListSitesCtrl', ($scope, $http) ->
  #$scope.mfl_sites = {items: [{foo: 1, bar: 'A'}, {foo: 2, bar: 'B'}, {foo: 3, bar: 'C'}], headers: ['foo', 'bar']}
  $scope.clear_mfl_sites = ->
    $scope.mfl_sites = {items: [], headers: [], loaded: false}

  $scope.seq = 0
  $scope.next_page_url = null
  $scope.clear_mfl_sites()

  $scope.$on 'curation-panel-node-chosen', (e, node) ->
    $scope.load_page()

  $scope.load_page = () ->
    $scope.seq += 1
    seq = $scope.seq

    if $scope.next_page_url != null
      page_request = $http.get($scope.next_page_url)
    else
      params = { params: {hierarchy: $scope.selected_node?.id, search: ""} }
      page_request = $http.get("/projects/#{$scope.project_id}/master/sites/search.json", params)

    page_request.success (data) ->
      # Check if there's a new request going on
      return if seq != $scope.pending_changes_seq

      $scope.mfl_sites.items = data.items
      $scope.mfl_sites.headers = data.headers
      $scope.mfl_sites.loaded = true

      #$scope.sites_loading = false

  $scope.load_page()

.controller 'SearchSiteCtrl', ($scope, $http) ->
  $scope.search_loading = false
  $scope.search = ''
  $scope.clear_sites()

  $scope._search_sites = ->
    if _.isEmpty($scope.search)
      $scope.mfl_sites.items = []
    else
      $scope.search_loading = true
      params = { search: $scope.search, hierarchy: $scope.selected_node?.id }
      $http.get("/projects/#{$scope.project_id}/master/sites/search", {params: params})
        .success (data) ->
          $scope.mfl_sites.items = data.items
          $scope.mfl_sites.headers = data.headers
          $scope.mfl_sites.loaded = true
          $scope.search_loading = false

  $scope.$watch 'search + selected_node.id', _.throttle($scope._search_sites, 200)

  $scope.$on 'site-search-clear', ->
    $scope.search = ''
    $scope._search_sites()

  # $scope.$on 'search-source-records-changed', (event, search) ->
  #   $scope.search = search

.controller 'SearchSourceRecordsCtrl', ($scope, $http) ->
  $scope.search_loading = false
  $scope.search = ''

  $scope._search_sites = ->
    $scope.$emit 'search-source-records', $scope.search

  $scope.$watch 'search + selected_node.id', _.throttle($scope._search_sites, 200)


.controller 'ConsolidateSiteCtrl', ($scope, $http) ->
  $scope.target_site = null
  $scope.consolidated_sites = null
  $scope.source_site = null

  $scope.$on 'site-search-selected', (e, site) ->
    $scope._select_target_site(site)

  $scope._select_target_site = (site) ->
    $scope.target_site = site

    # begin duplicate code consolidated_sites
    $scope.consolidated_sites = null
    return if $scope.target_site.id == null
    $http.get("/projects/#{$scope.project_id}/master/sites/#{$scope.target_site.id}/consolidated_sites")
      .success (data) ->
        $scope.consolidated_sites = data
    # end

  $scope.$on 'outside-pending-site-selected', (e, site) ->
    $scope.source_site = site
    return if $scope.source_site == null
    master_site_id = site.properties[$scope.app_master_site_id]
    if master_site_id
      $http.get("/projects/#{$scope.project_id}/master/sites/search", {params: {id: master_site_id}})
        .success (data) ->
          if data.length == 1
            $scope._select_target_site(data[0])

  $scope.create_target_site = ->
    $scope.target_site =
      id: null
      name: $scope.source_site.name
      lat: $scope.source_site.lat
      long: $scope.source_site.long
      properties: {}
    $scope.target_site.properties[$scope.hierarchy_target_field_code] = $scope.selected_node.id
    $scope.consolidated_sites = null

  $scope.go_to_search = ->
    $scope.target_site = null
    $scope.$broadcast('hide')

  $scope.go_to_and_reset_search = ->
    $scope.go_to_search()
    $scope.$broadcast('site-search-clear')

  $scope.is_target_site_new = ->
    $scope.target_site.id == null

  $scope.consolidate = ->
    $scope.consolidate_loading = true
    params = {
      source_site: {
        id: $scope.source_site.id,
        source_list_id: $scope.source_site.source_list.id
      }
      target_site: $scope.target_site
    }

    on_success = ->
      $scope.go_to_and_reset_search()
      $scope.$emit('site-dismissed', $scope.source_site)
      $scope.consolidate_loading = false

    if $scope.is_target_site_new()
      $http.post("/projects/#{$scope.project_id}/master/sites", params)
        .success ->
          on_success()
    else
      $http.post("/projects/#{$scope.project_id}/master/sites/#{$scope.target_site.id}", params)
        .success ->
          on_success()

.controller 'HierarchyChooser', ($scope) ->
  $scope.tree_visible = true
  $scope.list_visible = false

  $scope.select_tree = ->
    $scope.tree_visible = true
    $scope.list_visible = false

  $scope.select_list = ->
    $scope.tree_visible = false
    $scope.list_visible = true

  $scope.$watch 'tree_visible || list_visible', () ->
    $scope.expanded = $scope.tree_visible || $scope.list_visible
