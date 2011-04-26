http = require 'http'
Proxy = require 'node-proxy'
request = require 'request'
Log = require 'coloured-log'
log = new Log(Log.DEBUG)

# Database class
class Database
    constructor: (@db, options = {}) ->
        url = (options.protocol || 'http') + '://'
        url += options.host || 'localhost'
        url += ':' + (options.port || 5984)
        @uri = url + "/#{@db}/"

    # actions
    exists: (cb) ->
        @head '', (err, res, body) ->
            cb res.statusCode == 200
        this

    create: (cb) ->
        @exists (bool) =>
            @put '' if bool == false
            cb(this) if cb
    
    delete: (cb) ->
        @destroy '', cb

    # requests
    options: (method, path, data) ->
        options =
            method: method
            headers: {'Content-Type': 'application/json', 'Referer': 'http://localhost'}
            uri: @uri + path
            json: data

    request: (method, cb, path, data) ->
        request @options(method, path, data), (err, res, body) ->
            # log?
            cb(err, res, body) if cb

    # request helper methods
    destroy: (path, cb) ->
        @request('DELETE', cb, path)

    get: (path, cb) ->
        @request('GET', cb, path)

    head: (path, cb) ->
        @request('HEAD', cb, path)

    post: (path, data, cb) ->
        @request('POST', cb, path, data)

    put: (path, data, cb) ->
        @request('PUT', cb, path, data)

# Document class
class Document
    constructor: (@db, @data) ->
    save: (cb) ->
        method = if @data._id? then @db.put else @db.post
        method.call @db, @data._id, @data, (err, res, body) ->
            @data = body if 200 <= res.statusCode <= 202
            cb(err, res, body)
    isNew: -> @data._rev?


document_handler = (db, data) ->
    doc = new Document(db, data)

    getOwnPropertyDescriptor: (name) ->
        desc = Object.getOwnPropertyDescriptor(doc.data, name)
        if desc?
            desc.configurable = true
        desc
    getOwnPropertyNames: ->
        Object.getOwnPropertyNames(doc.data)
    getPropertyNames: ->
        Object.getPropertyNames(doc.data)
    defineProperty: (name, desc) ->
        Object.defineProperty(doc.data, name, desc)
    delete: (name) ->
        delete doc.data[name]
    fix: () ->
        if (Object.isFrozen(doc.data))
            Object.getOwnPropertyNames(doc.data).map (name) ->
                Object.getOwnPropertyDescriptor(doc.data, name)
        else
            undefined
    get: (rec, name) ->
        doc[name] || doc.data[name]
    set: (rec, name, value) ->
        doc.data[name] = value
    enumerate: ->
        response = []
        for key in doc.data
            response.push key
        response
    keys: ->
        Object.keys(doc.data)
    has: (name) ->
        name of doc.data
    hasOwn: (name) ->
        ({}).hasOwnProperty.call(doc.data, name)

# exports
exports.db = (db, options) ->
    new Database db, options
exports.doc = (db, data) ->
    Proxy.create(document_handler(db, data))
