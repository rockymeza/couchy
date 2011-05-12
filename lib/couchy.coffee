http = require 'http'
Proxy = require 'node-proxy'
request = require 'request'
url = require 'url'
sys = require 'sys'

# a default callback
noop = ->

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
  seed: (times, doc_cb, cb) ->
    if typeof(times) == 'function'
      cb = doc_cb
      doc_cb = times
      times = 1

    cb ?= noop

    seed = new Seed
    docs = []

    for i in [0...times]
      # do we need to instantiate a seed everytime?
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

# export
module.exports = couchy
