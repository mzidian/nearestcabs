###
# Matthew Zidian
# Nearest Cabs server.  Users a mongodb geolocation index to query cabs.
###

assert = require 'assert'

if process.env.VCAP_SERVICES
  env = JSON.parse(process.env.VCAP_SERVICES)
  mongo = env['mongodb-1.8'][0]['credentials']
else
  mongo =
    "hostname":"localhost"
    "port":27017
    "username":""
    "password":""
    "name":""
    "db":"nearestcabsdb"

generate_mongo_url = (obj) ->
  obj.hostname = (obj.hostname || 'localhost')
  obj.port = (obj.port || 27017)
  obj.db = (obj.db || 'nearestcabsdb')

  if obj.username && obj.password
    return "mongodb://" + obj.username + ":" + obj.password + "@" + obj.hostname + ":" + obj.port + "/" + obj.db
  else
    return "mongodb://" + obj.hostname + ":" + obj.port + "/" + obj.db


mongourl = generate_mongo_url(mongo)
console.log mongourl
db = require('mongojs').connect(mongourl, ['cabs'])
db.cabs.ensureIndex {loc:'2d'}

express = require 'express'
passport = require 'passport'
app = express()
app.configure ->
  app.use express.cookieParser()
  app.use express.bodyParser()
  app.use express.session { secret: 'keyboard cat' }
  app.use app.router
  #app.use express.static(__dirname + '/../../public')

###
is_logged_in = (req) -> req.session && req.session.user
login_out = (req, res, next) ->
  if is_logged_in(req)
    res.send "<a href='/logout'>logout</a><br/>"
  else
    res.send "<a href='/login'>login</a><br/>"
  next()
  
must_be_logged_in = (req, res, next) ->
  if is_logged_in(req)
    next(req.session.user.username)
  else
    res.redirect '/login'

logged_in_user = (req, res, next) ->
  must_be_logged_in req, res, (username) ->
    read_user username, (u) ->
      next u

db.cabs.find...
  update {id: id} newobj (err, item) ->
    ...
  insert
###

app.put '/cabs/:cab_id', (req, res) ->
  loc = req.body
  cab_id = req.params.cab_id
  console.log ("inserting cab #" + cab_id)
  console.log loc # should contain latitude longitude
  # if loc.latitude && loc.latitude >
  obj =
    cab_id: cab_id
    loc: [parseFloat(loc.longitude), parseFloat(loc.latitude)]
  db.cabs.remove {cab_id: cab_id}, (err, item) ->
    db.cabs.save obj, (err, item) ->
      if err
        console.log 'err:'
        console.log err
      #console.log 'saved ' + item
      #console.log 'should have saved '
      #console.log obj
      res.end()

format_cab_details = (item) ->
  "id": item.cab_id
  "longitude": item.loc[0]
  "latitude": item.loc[1]

app.get '/cabs/:cab_id', (req, res) ->
  cab_id = req.params.cab_id
  console.log ("getting details of cab #" + cab_id)
  db.cabs.findOne {'cab_id': cab_id}, (err, item) ->
    if err
      console.log err
      res.end()
    else if item
      res.end JSON.stringify format_cab_details item
    else
      res.end()

app.get '/cabs', (req, res) ->
  console.log "finding cabs near..."
  console.log req.query # should contain latitude longitude [limit radius]
  loc = [parseFloat(req.query.longitude),
         parseFloat(req.query.latitude)]
  limit = 8
  if req.query.limit
    limit = req.query.limit
  earthRadiusMeters = 6371000
  radius = 100000 #earthRadiusMeters * Math.PI / 12
  if req.query.radius
    radius = req.query.radius
  ctrSph = [loc, radius / earthRadiusMeters]
  dbquery =
    loc:
      '$within': # depricated. change to $geoWithin for mongodb version 2.4 
        '$centerSphere': ctrSph
  console.log dbquery
  console.log ctrSph
  db.cabs.find(dbquery, {}, {'limit': limit}).toArray (err, items) ->
    if err
      console.log "error finding close cabs:"
      console.log err
      res.end()
    else
      res.end JSON.stringify items.map format_cab_details
 
app.delete '/cabs/:cab_id', (req, res) ->
  cab_id = req.params.cab_id
  console.log ("destroying cab # " + cab_id)
  db.cabs.remove {'cab_id':cab_id}, (err, item) -> res.end()

app.delete '/cabs', (req, res) ->
  console.log "destrying all"
  db.cabs.remove (err, item) -> res.end() # send nothing

fs = require 'fs'
this.loaded_static_files = {}
static_file = (name, path, mime) =>
  fs.readFile './'+path, (err, data) =>
    if err
      throw err
    this.loaded_static_files[name] = data
  app.get '/'+name, (req, res) =>
    res.writeHeader 200, {"Content-Type": mime}
    res.end this.loaded_static_files[name]

#static_file_same_name = (name, type) -> static_file name, name, type

#static_file 'testClient.js', 'clients/testClient.js', 'application/javascript'
#static_file 'testClient.html', 'clients/testClient.html', 'text/html'
#static_file 'bulkTestClient.js', 'clients/bulkTestClient.js', 'application/javascript'
#static_file 'bulkTestClient.html', 'clients/bulkTestClient.html', 'text/html'
static_file 'mapClient.js', 'clients/mapClient.js', 'application/javascript'
static_file '', 'clients/mapClient.html', 'text/html'
static_file 'clientAPI.js', 'clients/clientAPI.js', 'application/javascript'
static_file 'jquery.min.js', 'libs/jquery.min.js', 'application/javascript'


app.listen(process.env.VCAP_APP_PORT || 3000)
console.log "listening on localhost:3000"

