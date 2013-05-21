###
# Matthew Zidian
# JavaScript functions for accessing the Nearest Cabs API
###

window.placeCab = (id, loc, next) ->
  $.ajax
    url: "/cabs/#{id}"
    type: "PUT"
    data:
      latitude: loc.latitude
      longitude: loc.longitude
    success: next

window.getCab = (id, next) ->
  $.ajax
    url: "/cabs/#{id}"
    type: "GET"
    success: parseJsonParam next
    error: (xhr, err) ->
      console.log xhr
      console.log err

window.getCabs = (qry, next) ->
  $.ajax
    url: "/cabs"
    type: "GET"
    data:
      latitude: qry.latitude
      longitude: qry.longitude
      limit: qry.limit
      radius: qry.radius
    success: parseJsonParam next

window.deleteCab = (id, next) ->
  $.ajax
    url: "/cabs/#{id}"
    type: "DELETE"
    success: next
    error: (xhr, err) ->
      console.log xhr
      console.log err

window.deleteAllCabs = (next) ->
  $.ajax
    url: "/cabs"
    type: "DELETE"
    success: next
    error: (xhr, err) ->
      console.log xhr
      console.log err

window.dist = (lat1, lon1, lat2, lon2) ->
  toRad = (deg) -> deg * Math.PI / 180
  R = 6371000 # earths radius in meters
  dLat = toRad (lat2-lat1)
  dLon = toRad (lon2-lon1)
  lat1 = toRad lat1
  lat2 = toRad lat2
  a = Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  R * c

parseJsonParam = (next) ->
  (json) ->
    if json
      next JSON.parse json
    else
      next undefined


