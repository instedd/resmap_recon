angular.module('Curation',['RmHierarchyService'])

.controller 'CurationPanel', ($scope, $http, RmHierarchyService) ->

  # Scope attributes
  $scope.merging = false
  $scope.selected_sites = {}
  $scope.target_mfl_site = null
  NodeService = RmHierarchyService.for($scope.master_collection_id, $scope.hierarchy_field_id)
  # Admin Tree
  $scope.selected_node = null

  # Source lists
  $scope.sites_loading = false
  $scope.source_sites_loading = []
  $scope.source_records_search = null
  $scope.selected_source_list = $scope.source_lists[1]

  # Initialization
  $scope.setup = () ->
    $scope.clear_sites()
    $scope.clear_mfl_sites()

  # Controller methods
  $scope.clear_sites = ->
    $scope.sites = {items: [], headers: [], loaded: false}

  $scope.clear_mfl_sites = ->
    $scope.mfl_sites = {items: [], headers: [], loaded: false}

  $scope.clear_selection = ->
    $scope.$broadcast 'clear-selection'

  $scope._reset_and_load_pending_changes = (page_to_load = 1) ->
    if $scope.selected_source_list && $scope.selected_source_list.id
      $scope.selected_source_lists = [$scope.selected_source_list]
    else
      $scope.selected_source_lists = $scope.source_lists.slice(1)

    $scope.source_sites = []
    new_selected_sites = {}
    for source in $scope.selected_source_lists
      $scope.source_sites[source.id] = {items: [], headers: [], loaded: false}
      $scope._load_pending_changes(source.id)
      if selected_sites = $scope.selected_sites[source.id]
        new_selected_sites[source.id] = selected_sites

    $scope.selected_sites = new_selected_sites

  $scope._load_pending_changes = (source_id, page_to_load = 1) ->
    if $scope.selected_source_list == undefined
      $scope.sites.loaded = true
      return
    $scope.source_sites_loading[source_id] = true
    params = params:
      target_value: $scope.selected_node?.id,
      search: $scope.source_records_search,
      page: page_to_load,
      source_list_id: source_id

    page_request = $http.get("/projects/#{$scope.project_id}/pending_changes", params)

    page_request.success (data) ->
      $scope.source_sites[source_id] = {
        items: data.sites,
        headers: data.headers,
        current_page: data.current_page
        total_count: data.total_count
        loaded: true
      }
      $scope.source_sites_loading[source_id] = false

  $scope.source_by_id = (source_id) ->
    source_id = parseInt(source_id)
    for source in $scope.source_lists
      if source.id == source_id
        return source

  $scope.source_name = (source_id) ->
    source = $scope.source_by_id(source_id)
    return source.name if source

  $scope.hierarchy_codes_to_paths = ->    
    $scope.mfl_sites.headers = (h for h in $scope.mfl_sites.headers when h.code != $scope.hierarchy_target_field_code)
    $scope.mfl_sites.headers.push {name: "Administrative Division", code: "admin_division_path"}

    for site in $scope.mfl_sites.items
      node = NodeService.node_by_id(site.properties[$scope.hierarchy_target_field_code])
      site.properties["admin_division_path"] = node.path

  $scope.load_mfl_page = (page_to_load = 1, search = "") ->
    params = { params: {hierarchy: $scope.selected_node?.id, search: search, page: page_to_load} }
    page_request = $http.get("/projects/#{$scope.project_id}/master/sites/search.json", params)

    page_request.success (data) ->
      $scope.mfl_sites.items = data.items
      $scope.mfl_sites.headers = data.headers

      $scope.mfl_sites.current_page = data.current_page
      $scope.mfl_sites.total_count = data.total_count

      $scope.mfl_sites.loaded = true

      $scope.hierarchy_codes_to_paths()

  $scope.view_reconciliations = () ->
    $http.get("/projects/#{$scope.project_id}/master/sites/#{$scope.target_mfl_site.id}/consolidated_sites")
      .success (sites) ->
        mapped_sites = {}
        for site in sites
          mapped_sites[site.source_list.id] ||= []
          mapped_sites[site.source_list.id].push(site)

        $scope.merge_source_sites = mapped_sites
        $scope.merge_mfl_site = $scope.target_mfl_site
        $scope.merging = true
        $scope.viewing_reconciliations = true

  $scope.open_merge = () ->
    $scope.merge_source_sites = $scope.selected_sites
    $scope.merge_mfl_site = $scope.target_mfl_site
    $scope.merging = true

  $scope.close_merge = () ->
    $scope.merging = false
    $scope.viewing_reconciliations = false

  $scope.create_target_site = ->
    return unless first_site = $scope.first_selected_site()
    $scope.merge_source_sites = $scope.selected_sites
    $scope.merge_mfl_site =
      id: null
      name: first_site.name
      lat: first_site.lat
      long: first_site.long
      properties: {}
    $scope.merge_mfl_site.properties[$scope.hierarchy_target_field_code] = $scope.selected_node.id
    $scope.check_for_duplicate(first_site.name)
    $scope.merging = true

  $scope.check_for_duplicate = (name) ->
    params = {params : {name: name, hierarchy: $scope.selected_node?.id} }
    request = $http.get("/projects/#{$scope.project_id}/master/sites/find_duplicates.json", params)
    request.success (data) ->
      $scope.merge_mfl_site.duplicate = data.duplicate

  $scope.dismiss = ->
    source_sites = []
    for _, sites of $scope.selected_sites
      for site in sites
        source_sites.push(id: site.id, source_list_id: site.source_list.id, mfl_hierarchy: site.mfl_hierarchy)

    return if source_sites.length == 0

    $http.post("/projects/#{$scope.project_id}/dismiss_source_sites", {source_sites: source_sites})
      .success ->
        $scope._reset_and_load_pending_changes()
        for site in sites
          $scope.lower_counters(site)

  $scope.first_selected_site = ->
    for _, sites of $scope.selected_sites
      if sites.length > 0
        return sites[0]

  $scope.source_site_empty = ->
    !$scope.first_selected_site()

  $scope.empty_source_or_target = ->
    !$scope.target_mfl_site || $scope.source_site_empty()

  $scope.lower_counters = (site) ->
    $scope.$broadcast 'site-removed', site.mfl_hierarchy

  # Event handling
  $scope.page_changed = (source_id, new_page) ->
    $scope._load_pending_changes source_id, new_page

  $scope.selection_changed = (source_id, selected_items) ->
    if selected_items && selected_items.length > 0
      $scope.selected_sites[source_id] = selected_items
    else
      delete $scope.selected_sites[source_id]

  $scope.mfl_selection_changed = (new_selected_item) ->
    $scope.target_mfl_site = new_selected_item

  $scope.mfl_page_changed = (new_page) ->
    $scope.$broadcast 'mfl-page-changed', new_page

  $scope.source_list_changed = (new_selected_source_list) ->
    $scope.selected_source_list = new_selected_source_list
    $scope._reset_and_load_pending_changes()

  $scope.$on 'tree-node-chosen', (e, node) ->
    $scope.selected_node = node
    $scope.clear_selection()
    # $scope._reset_and_load_pending_changes()
    $scope.load_mfl_page()

  $scope.$on 'search-source-records', (e, search) ->
    $scope.source_records_search = search
    $scope.$broadcast 'search-source-records-changed', search
    $scope._reset_and_load_pending_changes()
    $scope.load_mfl_page()

  # Let it begin!
  $scope.setup()


.controller 'SearchSiteCtrl', ($scope, $http) ->
  $scope.search_loading = false
  $scope.search = ''
  $scope.clear_sites()

  $scope._search_sites = ->
    if _.isEmpty($scope.search)
      $scope.mfl_sites.items = []
    else
      $scope.load_mfl_page(1, $scope.search)

  $scope.$watch 'search + selected_node.id', _.throttle($scope._search_sites, 200)

  $scope.$on 'site-search-clear', ->
    $scope.search = ''
    $scope._search_sites()

  $scope.$on 'search-source-records-changed', (event, search) ->
    $scope.search = search

  $scope.$on 'mfl-page-changed', (event, new_page) ->
    $scope.load_mfl_page(new_page, $scope.search)

.controller 'SearchSourceRecordsCtrl', ($scope, $http) ->
  $scope.search_loading = false
  $scope.search = ''

  $scope._search_sites = ->
    $scope.$emit 'search-source-records', $scope.search

  $scope.$watch 'search + selected_node.id', _.throttle($scope._search_sites, 200)


.controller 'MergePanel', ($scope, $http) ->
  clone = (obj) ->
    if not obj? or typeof obj isnt 'object'
      return obj

    if obj instanceof Date
      return new Date(obj.getTime()) 

    if obj instanceof RegExp
      flags = ''
      flags += 'g' if obj.global?
      flags += 'i' if obj.ignoreCase?
      flags += 'm' if obj.multiline?
      flags += 'y' if obj.sticky?
      return new RegExp(obj.source, flags) 

    newInstance = new obj.constructor()

    for key of obj
      newInstance[key] = clone obj[key]

    return newInstance

  $scope.header_for = (site, code) ->
    if source = $scope.source_by_id(site.source_list.id)
      source.headers[code]

  $scope.is_target_site_new = ->
    $scope.merge_mfl_site.id == null

  $scope.consolidate = ->
    return if $scope.merge_mfl_site.duplicate
    $scope.consolidate_loading = true
    first_site = $scope.first_selected_site()
    source_sites = []

    for _, sites of $scope.selected_sites
      for site in sites
        source_sites.push(id: site.id, source_list_id: site.source_list.id)

    mfl_site_to_merge = clone($scope.merge_mfl_site)
    delete mfl_site_to_merge.properties["admin_division_path"]

    params = {
      source_sites: source_sites
      target_site: mfl_site_to_merge
    }

    on_success = ->
      $scope.consolidate_loading = false
      $scope._reset_and_load_pending_changes()
      $scope.close_merge()
      $scope.clear_selection()
      $scope.lower_counters(first_site)
      $scope.load_mfl_page()

    if $scope.is_target_site_new()
      $http.post("/projects/#{$scope.project_id}/master/sites", params)
        .success ->
          $scope.mfl_sites.items.unshift($scope.merge_mfl_site)
          on_success()
    else
      $http.post("/projects/#{$scope.project_id}/master/sites/#{$scope.merge_mfl_site.id}", params)
        .success ->
          on_success()
