'use strict'

L.Icon.Default.imagePath = '/images/leaflet'

angular.module('africaApp', ['firebase'])
  .config ['$routeProvider', ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .when '/edit/:objectId',
        templateUrl: 'views/edit.html'
        controller: 'EditCtrl'
      .when '/edit/showNotes/:objectId/',
        templateUrl: 'views/edit.html'
        controller: 'EditCtrl'
      .otherwise
        redirectTo: '/'
  ]

app = angular.module('africaApp')

app.config ['$httpProvider', ($httpProvider) ->
  delete $httpProvider.defaults.headers.common['X-Requested-With']
] # X-Requested-With breaks CORS

app.service 'api', ['$http', ($http) ->
  baseURL = 'http://localhost:3001/?url=https://collections.artsmia.org/search_controller.php?'

  @gallery = (id, success, error) -> $http.get(baseURL + 'gallery=G' + id)
  @object = (id) -> $http.get(baseURL + 'details=' + id)
]

app.service 'objects', ['$http', ($http) ->
  featuredObjectIds = [102200, 108767, 111088, 111099, 111879, 111893, 113136, 114833, 115320, 115514, 1195, 12111, 1312, 13213, 1358, 1854, 1937, 30326, 45269, 4866, 5756, 97]
  @ids = -> featuredObjectIds
]

app.service 'nominatim', ['$http', ($http) ->
  @search = (query) ->
    $http.get('http://nominatim.openstreetmap.org/search?format=json&q='+query).then (d) ->
      if (match = d.data[0])
        [match.lat, match.lon]
]

