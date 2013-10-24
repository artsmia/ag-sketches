'use strict'

app = angular.module('africaApp')

app.controller 'EditCtrl', ['$scope', '$route', '$routeParams', '$location', '$http', 'angularFire', '$timeout', ($scope, $route, $routeParams, $location, $http, firebase, $timeout) ->
  $scope.id = $routeParams.objectId
  $scope.showNotes = !!$location.$$url.match(/showNotes/)
  annotationsPromise = firebase('//afrx.firebaseIO.com/' + $scope.id + '/notes2', $scope, 'annotations', [])

  # map $scope.annotations to their corresponding leaflet markers, we don't want those in firebase
  $scope.annotationsMarkers = {}
  $scope.getMarkerLayerForAnnotation = (note) -> $scope.annotationsMarkers[JSON.stringify(note.geometry)]

  # Add annotations to the map from firebase
  # `$scope.annotationsOnMap` indicates the animations that are already drawn,
  # so I can $scope.$watch for when annotations change and add any new ones that
  # come from another machine.
  $scope.annotationsOnMap = []
  $scope.setupDrawing = ->
    $scope.annotationsGroup = L.featureGroup()
    drawControl = new L.Control.Draw
      draw:
        circle: false
        polyline: false
        rectangle: {shapeOptions: {color: '#eee'}}
      edit: {featureGroup: $scope.annotationsGroup}
    $scope.zoom.map.addControl(drawControl)
    $scope.zoom.map.addLayer($scope.annotationsGroup)
    $scope.setAnnotationStyle()
  $scope.setAnnotationStyle = ->
    $scope.annotationsGroup.setStyle
      color: '#ddd'
      weight: 1

  $scope.addAnnotations = (_new, old) ->
    console.log(_new, old)
    angular.forEach $scope.annotations, (note) ->
      if note.removed
        $scope.removeAnnotation(note)
        console.log(note, "REMOVED")
      return if $scope.annotationsOnMap.indexOf(note.geometry) > -1
      $scope.annotate note
      $scope.setAnnotationStyle()

  $scope.removeAnnotation = (annotation) ->
    console.log "remove", annotation
    window.removing_note = annotation
    if marker = $scope.getMarkerLayerForAnnotation(annotation)
      console.log "removing", annotation, marker, zoomer.map._layers[marker]
      $scope.zoom.map.removeLayer(zoomer.map._layers[marker])
    $scope.removedAnnotations = annotation.geometry
    annotation.removed = true # this tells other clients to remove the annotation
    $timeout (-> $scope.annotations.splice($scope.annotations.indexOf(annotation), 1)), 500
    $scope.resetZoom()

  # Add an annotation
  # Either a single point or a bounding box
  # Save the geometry in an `eval()`able string
  $scope.annotate = (note) ->
    window.note = note
    window.json = L.GeoJSON.geometryToLayer(note.geometry)
    marker = $scope.annotationsGroup.addLayer(json)
    $scope.annotationsMarkers[JSON.stringify(note.geometry)] = json._leaflet_id

  $scope.panToAnnotation = (note) ->
    geometry = L.GeoJSON.geometryToLayer(note.geometry)
    console.log geometry
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
      tileProgress = firebase('//tilesaw.firebaseio.com/' + $scope.id, $scope, 'tileProgress', {})
      tileProgress.then (disconnect) ->
        cancelWatch = $scope.$watch 'tileProgress', ->
          if $scope.tileProgress && $scope.tileProgress.status == 'tiled'
            $scope.getTiles()
            disconnect() && cancelWatch()

  $scope.getTiles()
  $scope.setupMap = (data) ->
    tileURL = data.tiles[0].replace('http://0', '//{s}')
    $scope.zoom = Zoomer.zoom_image
      container: "map1"
      tileURL: tileURL
      imageWidth: data.width
      imageHeight: data.height

    $scope.setupDrawing()
    annotationsPromise.then ->
      $scope.addAnnotations()
      $scope.loading = false
      $scope.$watch 'annotations', $scope.addAnnotations

    $scope.zoom.map.on 'draw:created', (e) ->
      console.log('e', e, 'layerType', e.layerType, 'layer', e.layer)
      window.e = e
      $scope.annotations.push e.layer.toGeoJSON()
      $scope.$apply()

    $scope.resetZoom = -> $scope.zoom.map.centerImageAtExtents()
    $scope.toggleHelp = -> $scope.showHelp = !!!$scope.showHelp
]

