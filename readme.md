# African Gallery Sketches

Sketching out ideas for the reinstallation. Coming soon.

## Install

* `npm install` installs grunt and bower
* `npm install -g grunt-cli bower` installs the grunt and bower commands
* add /usr/local/share/npm/bin to $PATH
* `bower install` takes care of the JS dependencies
* `grunt server` fires it up

## Tilestream

The image tiles are being served through
[tilestream](//github.com/mapbox/tilestream).  They're in
[mbtiles](//github.com/mapbox/mbtiles) format, which means that all the
images are wrapped up in a sqlite3 database instead of
`{zoom}/{x}/{y}.jpg`. This is only important because image
width and height is included as metadata in each .mbtiles.

For now the images are tiled and served internally from my machine.

## Misc

Thanks to @walkerart for [flat_image_zoom.js](//github.com/walkerart/infolounge_walls/blob/master/javascripts/flat_image_zoom.js)
