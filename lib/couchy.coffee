http = require 'http'
Proxy = require 'node-proxy'
request = require 'request'
url = require 'url'
sys = require 'sys'

# a default callback
noop = ->

class CouchyError
  constructor: (@message, @response, @request) ->
  name: 'CouchyError'

requestOrError = (data, cb) ->
  request data, (err, res, body) ->
    throw err if err?

    body = JSON.parse(body) if body
    error = new CouchyError(body.error, body, data) if body.error?

    cb(error, res, body)

class Seed
  number: (max = 100, precision = 0) ->
    Math.round(Math.random() * max, precision)
  
  string: (length = 10) ->
    ret = []
    for i in [1..length]
      ret.push(@number(57) + 65) # 65-122 (A-z)

    String.fromCharCode.apply(null, ret)

  pick: (choices) ->
    choices[@number(choices.length - 1)]

class App
  constructor: (@db, @name) ->
    @views =  {}
    @updates = {}
    @shows = {}
    @lists = {}
    @id = '_design/' + @name

  toJSON: ->
    {views: @views, updates: @updates, shows: @shows, lists: @lists}

  toString: ->
    JSON.stringify(@prepare(@toJSON()))

  prepare: (obj) ->
    for i of obj
      switch typeof obj[i]
        when 'function'
          obj[i] = obj[i].toString()
        when 'object'
          obj[i] = @prepare(obj[i])
    obj

  push: (cb) ->
    @db.query 'put', @id, @prepare(@toJSON()), cb

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
    
    requestOrError {uri: uri, method: method, json: data}, cb

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

  app: (name) ->
    new App(this, name)

  # seeding
  seed: (times, doc_cb, cb) ->
    if typeof(times) == 'function'
      cb = doc_cb
      doc_cb = times
      times = 1

    cb ?= noop

    seed = new Seed
    docs = []

    for i in [0...times]
      docs.push doc_cb.call(seed)

    bulk =
      all_or_nothing: true
      docs: docs

    @query 'post', '_bulk_docs', bulk, (err, res, body) =>
      cb(err, docs, body)
    undefined

couchy = (uri) ->
  new Database(url.parse(uri))

# for type checking
couchy.Database = Database
couchy.Seed = Seed
couchy.App = App

# export
module.exports = couchy
