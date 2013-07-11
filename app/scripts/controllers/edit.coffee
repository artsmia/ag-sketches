'use strict'

app = angular.module('africaApp')

app.controller 'EditCtrl', ['$scope', '$route', '$routeParams', '$location', '$http', 'angularFire', '$timeout', ($scope, $route, $routeParams, $location, $http, firebase, $timeout) ->
  window.$scope = $scope
  $scope.id = $routeParams.objectId
  annotationsPromise = firebase('//afrx.firebaseIO.com/' + $scope.id + '/notes', $scope, 'annotations', [])

  # Add annotations to the map from firebase
  # `$scope.annotationsOnMap` indicates the animations that are already drawn,
  # so I can $scope.$watch for when annotations change and add any new ones that
  # come from another machine.
  $scope.annotationsOnMap = []
  $scope.addAnnotations = (_new, old) ->
    console.log(_new, old)
    angular.forEach $scope.annotations, (note) ->
      return if $scope.annotationsOnMap.indexOf(note.geometry) > -1
      $scope.annotationsOnMap.push note.geometry
      $scope.annotate
        body: note.body
        geometry: eval(note.geometry)
        _annotation: note

  $scope.removeAnnotation = (annotation) ->
    $scope.annotations.splice($scope.annotations.indexOf(annotation), 1)
    $scope.zoom.map.removeLayer(zoomer.map._layers[annotation.marker]) if annotation.marker
    $scope.resetZoom()

  # Add an annotation
  # Either a single point or a bounding box
  # Save the geometry in an `eval()`able string
  $scope.annotate = (options) ->
    [stringified_geometry, marker] = if options.geometry instanceof L.LatLng
      ll = options.geometry
      ["L.latLng(" + JSON.stringify([ll.lat, ll.lng]) + ")",
       L.marker(ll)]
    else if options.geometry instanceof L.LatLngBounds
      box = options.geometry
      [sw, ne] = [box._southWest, box._northEast]
      ["L.latLngBounds(" + JSON.stringify([[sw.lat, sw.lng], [ne.lat, ne.lng]]) + ")",
       L.rectangle(box, {color: "#ff7800", weight: 1, test: 1234})]

    marker.addTo(zoomer.map)

    if note = options._annotation
      note.marker = marker._leaflet_id
      note
    else
      $scope.annotations.push
        body: options.body || 'New Annotation'
        geometry: stringified_geometry
        marker: marker._leaflet_id

  $scope.panToAnnotation = (ann) ->
    geometry = eval(ann.geometry)
    if geometry instanceof L.LatLngBounds
      $scope.zoom.map.fitBounds(geometry)
    else
      $scope.zoom.map.panTo(geometry)
    $scope.activeNote = ann

  $scope.deactivate = (ann) ->
    $scope.activeNote = undefined
    zoomBackOut = -> $scope.resetZoom() unless $scope.activeNote
    # TODO: $scope.popView keeps the old ([lat, lng], zoom) and restores that
    # view?
    $timeout zoomBackOut, 500

  $scope.loading = true
  $http.get("http://clog.local:8888/v2/#{$scope.id}.json").then (response) ->
    data = response.data
    $scope.zoom = Zoomer.zoom_image
      container: "map1"
      tileURL: data.tiles[0]
      imageWidth: data.width
      imageHeight: data.height

    annotationsPromise.then ->
      $scope.addAnnotations()
      $scope.loading = false
      $scope.$watch 'annotations', $scope.addAnnotations

    $scope.zoom.map.on 'click touch', (touch) ->
      if touch.originalEvent.metaKey
        $scope.annotate {geometry: touch.latlng}
        $scope.$apply()

    $scope.zoom.map.on 'boxmarkerend', (box) ->
      $scope.annotate
        geometry: box.boxZoomBounds
      $scope.$apply()

    $scope.resetZoom = -> $scope.zoom.map.centerImageAtExtents()
    $scope.toggleHelp = -> $scope.showHelp = !!!$scope.showHelp
]

