###
# Matthew Zidian
# Web client for Nearest Cabs API
# Loads cabs within a radius of twice the distance from the center of the map to the corner
# or 100000km (whichever is smaller).
# I use twice the distance so as you scroll cabs out of view are pre-fetched.
###

map = 0
cabs = {}
initialize = () ->
  mapOptions =
    zoom: 12
    #center: new google.maps.LatLng(-34.397, 150.644)
    mapTypeId: google.maps.MapTypeId.ROADMAP
  map = new google.maps.Map document.getElementById('map-canvas'), mapOptions

  if navigator.geolocation
    navigator.geolocation.getCurrentPosition (position) ->
      pos = new google.maps.LatLng position.coords.latitude,
                                   position.coords.longitude
      map.setCenter pos
    , () ->
      handleNoGeolocation true
  else
    # Browser doesn't support Geolocation
    handleNoGeolocation false

  # todo: update radius when bounding box changes
  google.maps.event.addListener map, "center_changed", handleViewChange
  google.maps.event.addListener map, "bounds_changed", handleViewChange
  google.maps.event.addListener map, "zoom_changed", handleViewChange

  $('#cab_id').keyup (e) -> if e.keyCode == 13 then addFindCab()
  $('#add_find_cab_btn').click addFindCab
  $('#delete_cab_id').keyup (e) -> if e.keyCode == 13 then deleteCabHdlr()
  $('#delete_cab_btn').click deleteCabHdlr
  $('#delete_all_cabs_btn').click () ->
    deleteAllCabs()
    for id, cab of cabs
      cab.setMap null
    cabs = {}

handleViewChange = () ->
  pos = map.getCenter()
  console.debug "getting cabs near #{pos.lat()}, #{pos.lng()}"
  wpos = wrapLatLng pos
  if Math.abs(wpos.lon) < 170 and Math.abs(wpos.lat) < 80
    corner = wrapLatLng map.getBounds().getNorthEast()
    radius = Math.min 100000, 2 * dist(wpos.lat, wpos.lon, corner.lat, corner.lon)
    getCabs {latitude: wpos.lat, longitude: wpos.lon, radius: radius, limit: 1000}, (closeCabs) ->
      newCabs = {}
      for cab in closeCabs
        console.debug "got cab:"
        console.debug cab
        newCabs[cab.id] = true
        addCab cab.id, new google.maps.LatLng(cab.latitude, cab.longitude)
      for id,cab of cabs
        if not newCabs[id]
          cab.setMap null
          delete cabs[id]


wrapLatLng = (pos) ->
  wrap = (deg, max) ->
    poz = (deg + max/2) % max
    poz + (if poz > 0 then -max/2 else max/2)
  lat: wrap pos.lat(), 180
  lon: wrap pos.lng(), 360

addFindCab = () ->
  id = parseInt $('#cab_id').val()
  if id
    console.debug "finding cab ##{id}"
    getCab id, (cab) ->
      if cab
        map.panTo(new google.maps.LatLng(cab.latitude, cab.longitude))
      else
        console.debug "adding cab"
        addAndPlaceCab id, map.getCenter()
  
deleteCabHdlr = () ->
  id = parseInt $('#delete_cab_id').val()
  if id
    deleteCab id, () ->
      cabs[id].setMap null
      delete cabs[id]
       
handleNoGeolocation = (errorFlag) ->
  if errorFlag
    content = "Error: The Geolocation service failed."
  else
    content = "Error: Your browser doesn't support geolocation."

  options =
    map: map
    position: new google.maps.LatLng 60, 105
    content: content

  infowindow = new google.maps.InfoWindow options
  map.setCenter options.position

addCab = (id, latlng, animation) ->
  if cabs[id]
    cabs[id].setPosition(latlng)
  else
    marker = new google.maps.Marker
      icon: "http://chart.googleapis.com/chart?chst=d_bubble_icon_text_small&chld=taxi|bbT|#{id}|0000FF|eee"
      position: latlng
      draggable: true
      animation: animation
      map: map
    cabs[id] = marker
    google.maps.event.addListener marker, 'dragend', () ->
      pos = marker.getPosition()
      placeCab id, {latitude: pos.lat(), longitude: pos.lng()}, () -> 0

addAndPlaceCab = (id, pos) ->
  placeCab id, {latitude: pos.lat(), longitude: pos.lng()}, () ->
    addCab id, pos, google.maps.Animation.DROP

google.maps.event.addDomListener window, 'load', initialize

