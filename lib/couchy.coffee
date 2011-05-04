http = require 'http'
Proxy = require 'node-proxy'
request = require 'request'
Log = require 'coloured-log'
log = new Log(Log.DEBUG)

class Connection
    constructor: (options = {}) ->
        url = (options.protocol || 'http') + '://'
        url += options.host || 'localhost'
        url += ":#{options.port || 5984}/"
        @url = url

    # requests
    options: (method, path, data) ->
        options =
            method: method
            headers: {'Content-Type': 'application/json', 'Referer': 'http://localhost'}
            uri: @url + path
            json: data

    request: (method, cb, path, data) ->
        request @options(method, path, data), (err, res, body) =>
            if err
                log.debug @options(method, path, data).uri
                throw new Error(err)
            cb(err, res, body) if cb

    # request helper methods
    delete: (path, cb) ->
        @request('DELETE', cb, path)

    get: (path, cb) ->
        @request('GET', cb, path)

    head: (path, cb) ->
        @request('HEAD', cb, path)

    post: (path, data, cb) ->
        @request('POST', cb, path, data)

    put: (path, data, cb) ->
        @request('PUT', cb, path, data)


# Database class
class Database extends Connection
    constructor: (@db, options = {}) ->
        super options
        @url += @db + "/"

    # actions
    exists: (cb) ->
        @head '', (err, res, body) ->
            cb res.statusCode == 200
        this

    create: (cb) ->
        @exists (bool) =>
            @put '' if bool == false
            cb(this) if cb
    
    destroy: (cb) ->
        @delete '', cb

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

    return {
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
            Object.keys(doc.data)
        keys: ->
            Object.keys(doc.data)
    }

# exports
exports.db = (db, options) ->
    new Database(db, options)
exports.doc = (db, data) ->
    Proxy.create(document_handler(db, data))
exports.connection = (options) ->
    new Connection(options)
