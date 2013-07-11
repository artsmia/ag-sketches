'use strict'

app = angular.module('africaApp')

app.controller 'MainCtrl', ['$scope', 'api', 'objects', '$timeout', 'nominatim', ($scope, api, objects, $timeout, nominatim) ->
  window.$scope = $scope

  $scope.objectIds = objects.ids()
]
