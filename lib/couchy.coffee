http = require 'http'
Proxy = require 'node-proxy'
request = require 'request'
url = require 'url'
sys = require 'sys'

# a default callback
noop = ->

class Seed
  constructor: (@doc) ->

  rand: (max = 100, precision = 0) ->
    Math.round(Math.random * max, precision)

class Database
  constructor: (@url) ->
    @url.hostname ||= 'localhost'
    @url.port ||= 5984
    @url.protocol ||= 'http:'

  query: (method, path, data, cb = noop) ->
    # turns the URL object into a string
    uri = url.format(@url)
    # for more relaxed method invocation
    if path?
      if typeof path != 'string'
        cb = data
        data = path
      else
        uri += '/' + path
    if data? and typeof data != 'object'
      cb = data
    
    request {uri: uri, method: method, json: data}, (err, res, body) ->
      console.error err if err?
      body = JSON.parse(body) if body
      cb(err, res, body)

  # setup methods
  exists: (cb) ->
    @query 'head', (err, res) =>
      cb(err, res.statusCode == 200)
    undefined

  create: (cb) ->
    @exists (err, bool) =>
      if not bool
        @query 'put', (err, res, body) =>
          cb(err, res.statusCode == 201)
      else
        cb(null, true)
    undefined

  destroy: (cb) ->
    @query 'delete', cb

  # seeding
  seed: (doc_cb, cb) ->
    doc = doc_cb.call(new Seed)
    @query 'post', doc, (err, res, body) =>
      if res.statusCode == 201
        doc._id = body.id
        doc._rev = body.rev
      cb(err, doc)
    undefined

couchy = (uri) ->
  new Database(url.parse(uri))

# for type checking
couchy.Database = Database

# export
module.exports = couchy
