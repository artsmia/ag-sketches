!function(){"use strict";var a;L.Icon.Default.imagePath="/images/leaflet",angular.module("africaApp",["firebase"]).config(["$routeProvider",function(a){return a.when("/",{templateUrl:"views/main.html",controller:"MainCtrl"}).when("/edit/:objectId",{templateUrl:"views/edit.html",controller:"EditCtrl"}).when("/edit/showNotes/:objectId/",{templateUrl:"views/edit.html",controller:"EditCtrl"}).otherwise({redirectTo:"/"})}]),a=angular.module("africaApp"),a.config(["$httpProvider",function(a){return delete a.defaults.headers.common["X-Requested-With"]}]),a.service("api",["$http",function(a){var b;return b="http://localhost:3001/?url=https://collections.artsmia.org/search_controller.php?",this.gallery=function(c){return a.get(b+"gallery=G"+c)},this.object=function(c){return a.get(b+"details="+c)}}]),a.service("objects",["$http",function(){var a;return a=[102200,108767,111088,111099,111879,111893,113136,114833,115320,115514,1195,12111,1312,13213,1358,1854,1937,30326,45269,4866,5756,97],this.ids=function(){return a}}]),a.service("nominatim",["$http",function(a){return this.search=function(b){return a.get("http://nominatim.openstreetmap.org/search?format=json&q="+b).then(function(a){var b;return(b=a.data[0])?[b.lat,b.lon]:void 0})}}])}.call(this),function(){"use strict";var a;a=angular.module("africaApp"),a.controller("MainCtrl",["$scope","api","objects","$timeout","nominatim",function(a,b,c){return window.$scope=a,a.objectIds=c.ids()}])}.call(this),function(){"use strict";var a;a=angular.module("africaApp"),a.controller("EditCtrl",["$scope","$route","$routeParams","$location","$http","angularFire","$timeout",function(a,b,c,d,e,f,g){var h,i;return a.id=c.objectId,a.showNotes=!!d.$$url.match(/showNotes/),h=f("//afrx.firebaseIO.com/"+a.id+"/notes2",a,"annotations",[]),a.annotationsMarkers={},a.getMarkerLayerForAnnotation=function(b){return a.annotationsMarkers[JSON.stringify(b.geometry)]},a.setupDrawing=function(){var b;return a.annotationsGroup=L.featureGroup(),b=new L.Control.Draw({draw:{circle:!1,polyline:!1,marker:!1,rectangle:{shapeOptions:{color:"#eee"}}},edit:{featureGroup:a.annotationsGroup}}),a.zoom.map.addControl(b),a.zoom.map.addLayer(a.annotationsGroup),a.setAnnotationStyle()},a.setAnnotationStyle=function(){return a.annotationsGroup.setStyle({color:"#ddd",weight:1})},a.addAnnotations=function(){return angular.forEach(a.annotations,function(b){return b.removed&&a.removeAnnotation(b),a.getMarkerLayerForAnnotation(b)?void 0:(a.annotate(b),a.setAnnotationStyle())})},a.removeAnnotation=function(b){var c;return(c=a.getMarkerLayerForAnnotation(b))&&a.zoom.map.removeLayer(zoomer.map._layers[c]),a.removedAnnotations=b.geometry,b.removed=!0,g(function(){return a.annotations.splice(a.annotations.indexOf(b),1)},500),a.resetZoom()},a.annotate=function(b){var c,d;return b=b,c=L.GeoJSON.geometryToLayer(b.geometry),d=a.annotationsGroup.addLayer(c),a.annotationsMarkers[JSON.stringify(b.geometry)]=c._leaflet_id},a.panToAnnotation=function(b){var c;return c=L.GeoJSON.geometryToLayer(b.geometry),c instanceof L.Marker?a.zoom.map.panTo(c._latlng):a.zoom.map.fitBounds(c),a.activeNote=b},a.deactivate=function(){var b;return a.activeNote=void 0,b=function(){return a.activeNote?void 0:a.resetZoom()},g(b,500)},a.loading=!0,i="http://tilesaw.dx.artsmia.org/"+a.id+".tif",a.getTiles=function(){var b;return b=e.get(i),b.success(function(b){return a.setupMap(b),a.tileProgress=""}),b.error(function(){var b;return b=f("//tilesaw.firebaseio.com/"+a.id,a,"tileProgress",{}),b.then(function(b){var c;return c=a.$watch("tileProgress",function(){return a.tileProgress&&"tiled"===a.tileProgress.status?(a.getTiles(),b()&&c()):void 0})})})},a.getTiles(),a.setupMap=function(b){var c;return c=b.tiles[0].replace("http://0","//{s}"),a.zoom=Zoomer.zoom_image({container:"map1",tileURL:c,imageWidth:b.width,imageHeight:b.height}),a.setupDrawing(),h.then(function(){return a.loading=!1,a.$watch("annotations",a.addAnnotations)}),a.zoom.map.on("draw:created",function(b){return a.annotations.push(b.layer.toGeoJSON()),a.$apply()}),a.zoom.map.on("draw:edited",function(b){return b.layers.eachLayer(function(b){var c;return c=b.toGeoJSON(),angular.forEach(a.annotations,function(b){return _.isEqual(b.geometry.coordinates[0][0],c.geometry.coordinates[0][0])?(a.annotations[a.annotations.indexOf(b)]=c,a.$apply()):void 0})})}),a.zoom.map.on("draw:deleted",function(b){return b.layers.eachLayer(function(b){var c;return c=b.toGeoJSON(),angular.forEach(a.annotations,function(b){return _.isEqual(b.geometry,c.geometry)?(a.annotations.splice(a.annotations.indexOf(b),1),a.$apply()):void 0})})}),a.resetZoom=function(){return a.zoom.map.centerImageAtExtents()},a.toggleHelp=function(){return a.showHelp=!a.showHelp}}}])}.call(this);