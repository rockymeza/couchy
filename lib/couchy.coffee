http = require 'http'
Proxy = require 'node-proxy'
request = require 'request'
url = require 'url'
sys = require 'sys'

# a default callback
noop = ->

class CouchyError extends Error
  constructor: (@message, @response, @request) ->
  name: 'CouchyError'
class RequestError extends CouchyError

requestOrError = (data, cb) ->
  request data, (err, res, body) ->
    throw err if err?

    body = JSON.parse(body) if body
    error = new RequestError(body.error, body, data) if body.error?

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
    @_id = '_design/' + @name
    @_rev = undefined

  attributes: ['_id', '_rev', 'views', 'updates', 'shows', 'lists']

  toJSON: ->
    hash = {}
    for i in @attributes
      hash[i] = this[i]
    hash

  fromJSON: (hash) ->
    for i in @attributes
      this[i] = hash[i]

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

  unprepare: (obj) ->
    for i of obj
      if obj[i].substr(0, 8) == 'function'
        obj[i] = eval(obj[i])
    obj

  push: (cb) ->
    @db.query 'put', @_id, @prepare(@toJSON()), cb

  pull: (cb) ->
    @db.query 'get', @_id, (err, res, body) =>
      @fromJSON(body)
      cb(err, this)


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
