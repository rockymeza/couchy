http = require 'http'
Proxy = require 'node-proxy'
request = require 'request'
url = require 'url'
sys = require 'sys'


# class Connection
#     constructor: (options = {}) ->
#         url = (options.protocol || 'http') + '://'
#         url += options.host || 'localhost'
#         url += ":#{options.port || 5984}/"
#         @url = url
# 
#     # requests
#     options: (method, path, data) ->
#         options =
#             method: method
#             headers: {'Content-Type': 'application/json', 'Referer': 'http://localhost'}
#             uri: @url + path
#             json: data
# 
#     request: (method, cb, path, data) ->
#         request @options(method, path, data), (err, res, body) =>
#             if err
#                 log.debug @options(method, path, data).uri
#                 throw new Error(err)
#             cb(err, res, body) if cb
# 
#     # request helper methods
#     delete: (path, cb) ->
#         @request('DELETE', cb, path)
# 
#     get: (path, cb) ->
#         @request('GET', cb, path)
# 
#     head: (path, cb) ->
#         @request('HEAD', cb, path)
# 
#     post: (path, data, cb) ->
#         @request('POST', cb, path, data)
# 
#     put: (path, data, cb) ->
#         @request('PUT', cb, path, data)
# 
# 
# # Database class
# class Database extends Connection
#     constructor: (@db, options = {}) ->
#         super options
#         @url += @db + "/"
# 
#     # actions
#     exists: (cb) ->
#         @head '', (err, res, body) ->
#             cb res.statusCode == 200
#         this
# 
#     create: (cb) ->
#         @exists (bool) =>
#             @put '' if bool == false
#             cb(this) if cb
#     
#     destroy: (cb) ->
#         @delete '', cb
# 
# # Document class
# class Document
#     constructor: (@db, @data) ->
#     save: (cb) ->
#         method = if @data._id? then @db.put else @db.post
#         method.call @db, @data._id, @data, (err, res, body) ->
#             @data = body if 200 <= res.statusCode <= 202
#             cb(err, res, body)
#     isNew: -> @data._rev?
# 
# 
# document_handler = (db, data) ->
#     doc = new Document(db, data)
# 
#     return {
#         getOwnPropertyDescriptor: (name) ->
#             desc = Object.getOwnPropertyDescriptor(doc.data, name)
#             if desc?
#                 desc.configurable = true
#             desc
#         getOwnPropertyNames: ->
#             Object.getOwnPropertyNames(doc.data)
#         getPropertyNames: ->
#             Object.getPropertyNames(doc.data)
#         defineProperty: (name, desc) ->
#             Object.defineProperty(doc.data, name, desc)
#         delete: (name) ->
#             delete doc.data[name]
#         fix: () ->
#             if (Object.isFrozen(doc.data))
#                 Object.getOwnPropertyNames(doc.data).map (name) ->
#                     Object.getOwnPropertyDescriptor(doc.data, name)
#             else
#                 undefined
#         get: (rec, name) ->
#             doc[name] || doc.data[name]
#         set: (rec, name, value) ->
#             doc.data[name] = value
#         enumerate: ->
#             response = []
#             for key in doc.data
#                 response.push key
#             response
#             Object.keys(doc.data)
#         keys: ->
#             Object.keys(doc.data)
#     }


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
    uri = url.format(@url)

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
