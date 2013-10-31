'use strict'

app = angular.module('africaApp')

app.controller 'EditCtrl', ['$scope', '$route', '$routeParams', '$location', '$http', 'angularFire', '$timeout', ($scope, $route, $routeParams, $location, $http, firebase, $timeout) ->
  $scope.id = $routeParams.objectId
  $scope.showNotes = !!$location.$$url.match(/showNotes/)
  annotationsPromise = firebase(new Firebase('//afrx.firebaseIO.com/' + $scope.id + '/notes2'), $scope, 'annotations', [])

  # map $scope.annotations to their corresponding leaflet markers, so we can access
  # them later.
  # It's two way: `stringified json -> _leaflet_id` and
  # _leaflet_id -> firebase object`.
  # With the first (`json -> id`) we can check if a given region has been drawn on
  # the map yet.
  # The second lets us update firebase when a region is changed through L.draw
  $scope.annotationsMarkers = {}
  $scope.getMarkerLayerForAnnotation = (note) -> $scope.annotationsMarkers[JSON.stringify(note.geometry)]

  $scope.setupDrawing = ->
    $scope.annotationsGroup = L.featureGroup()
    drawControl = new L.Control.Draw
      draw:
        circle: false
        polyline: false
        marker: false
        rectangle: {shapeOptions: {color: '#eee'}}
      edit: {featureGroup: $scope.annotationsGroup}
    $scope.zoom.map.addControl(drawControl)
    $scope.zoom.map.addLayer($scope.annotationsGroup)
    $scope.setAnnotationStyle()
  $scope.setAnnotationStyle = ->
    $scope.annotationsGroup.setStyle
      color: '#ddd'
      weight: 1

  # Add annotations to the map from firebase
  # `$scope.annotationsMarkers` indicates the animations that are already drawn,
  # so I can $scope.$watch for when annotations change and add any new ones that
  # come from another machine.
  $scope.addAnnotations = (_new, old) ->
    angular.forEach $scope.annotations, (note) ->
      if note.removed
        $scope.removeAnnotation(note)
      return if $scope.getMarkerLayerForAnnotation(note)
      $scope.annotate note
      $scope.setAnnotationStyle()

  $scope.removeAnnotation = (annotation) ->
    if marker = $scope.getMarkerLayerForAnnotation(annotation)
      $scope.zoom.map.removeLayer(zoomer.map._layers[marker])
    $scope.removedAnnotations = annotation.geometry
    annotation.removed = true # this tells other clients to remove the annotation
    $timeout (-> $scope.annotations.splice($scope.annotations.indexOf(annotation), 1)), 500
    $scope.resetZoom()

  # Add an annotation
  # Either a single point or a bounding box
  # Save the geometry in an `eval()`able string
  $scope.annotate = (note) ->
    note = note
    json = L.GeoJSON.geometryToLayer(note.geometry)
    marker = $scope.annotationsGroup.addLayer(json)
    $scope.annotationsMarkers[JSON.stringify(note.geometry)] = json._leaflet_id
    $scope.annotationsMarkers[json._leaflet_id] = note

  $scope.panToAnnotation = (note) ->
    geometry = L.GeoJSON.geometryToLayer(note.geometry)
    unless geometry instanceof L.Marker
      $scope.zoom.map.fitBounds(geometry)
    else
      $scope.zoom.map.panTo(geometry._latlng)
    $scope.activeNote = note

  $scope.deactivate = (ann) ->
    $scope.activeNote = undefined
    zoomBackOut = -> $scope.resetZoom() unless $scope.activeNote
    # TODO: $scope.popView keeps the old ([lat, lng], zoom) and restores that
    # view?
    $timeout zoomBackOut, 500

  $scope.loading = true

  tileJson = "http://tilesaw.dx.artsmia.org/#{$scope.id}.tif"
  $scope.getTiles = ->
    http = $http.get(tileJson)
    http.success (data, status) ->
      $scope.setupMap(data)
      $scope.tileProgress = ''
    http.error ->
      tileProgress = firebase(new Firebase('//tilesaw.firebaseio.com/' + $scope.id), $scope, 'tileProgress', {})
      tileProgress.then (disconnect) ->
        cancelWatch = $scope.$watch 'tileProgress', ->
          if $scope.tileProgress && $scope.tileProgress.status == 'tiled'
            $scope.getTiles()
            disconnect() && cancelWatch()

  $scope.getTiles()
  $scope.setupMap = (data) ->
    tileURL = data.tiles[0].replace('http://0', '//{s}')
    Zoomer.zoomers = []
    $scope.zoom = Zoomer.zoom_image
      container: "map1"
      tileURL: tileURL
      imageWidth: data.width
      imageHeight: data.height

    $scope.setupDrawing()
    annotationsPromise.then ->
      $scope.loading = false
      $scope.$watch 'annotations', $scope.addAnnotations

    $scope.zoom.map.on 'draw:created', (e) ->
      $scope.annotations.push e.layer.toGeoJSON()
      $scope.$apply()

    $scope.zoom.map.on 'draw:edited', (e) ->
      e.layers.eachLayer (layer) ->
        if note = $scope.annotationsMarkers[layer._leaflet_id]
          newGeoJSON = layer.toGeoJSON()
          newGeoJSON.properties = note.properties # Stay linked to the same detail in WP
          $scope.annotations[$scope.annotations.indexOf(note)] = newGeoJSON
          $scope.$apply()

    $scope.zoom.map.on 'draw:deleted', (e) ->
      e.layers.eachLayer (layer) ->
        layerJSON = layer.toGeoJSON()
        if note = $scope.annotationsMarkers[layer._leaflet_id]
          $scope.annotations.splice($scope.annotations.indexOf(note), 1)
          $scope.$apply()

    $scope.resetZoom = -> $scope.zoom.map.centerImageAtExtents()
    $scope.toggleHelp = -> $scope.showHelp = !!!$scope.showHelp
]

