base = angular.module('Rails', [])

base.config ["$httpProvider", ($httpProvider) ->
  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')

  interceptor = ["$q", "$injector", ($q, $injector) ->
    success = (response) ->
      $http = $http || $injector.get('$http')
      if($http.pendingRequests.length < 1)
        $('#globalLoading').hide()
      response
    error = (response) ->
      $http = $http || $injector.get('$http');
      if($http.pendingRequests.length < 1)
        $('#globalLoading').hide()
      $('#errorModal').modal('show')
      $q.reject response
    (promise) ->
      $('#globalLoading').show()
      promise.then success, error
  ]
  $httpProvider.responseInterceptors.push interceptor
]
