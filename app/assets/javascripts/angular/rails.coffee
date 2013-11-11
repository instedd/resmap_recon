base = angular.module('Rails', [])

base.config ["$httpProvider", ($httpProvider) ->
  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')

  interceptor = ["$rootScope", "$q", (scope, $q) ->
    success = (response) ->
      response
    error = (response) ->
      $('#errorModal').modal('show')
      $q.reject response
    (promise) ->
      promise.then success, error
  ]
  $httpProvider.responseInterceptors.push interceptor
]
