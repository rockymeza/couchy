http = require 'http'
Proxy = require 'node-proxy'

request = (options, cb) ->
    response = ''
    req = http.request options, (res) ->
        res.setEncoding('utf8')
        res.on 'data', (chunk) ->
            response += chunk
        res.on 'end', ->
            response and response = JSON.parse(response)
            cb res.statusCode, response if cb?

    req.write(options.data || '', 'utf8')
    req.end()

# Database class
class Database
    constructor: (@db, options = {}) ->
        @host = options.host || 'localhost'
        @port = options.port || 5984
        @path = "/#{@db}/"

    # actions
    exists: (cb) ->
        @head '', (status, response) ->
            cb.call(this, status == 200)
        this

    create: ->
        @exists (bool) ->
            @put '' if bool == false

    # requests
    options: (method, path, data) ->
        options =
            host: @host
            port: @port
            headers: {'Content-Type': 'application/json'}
            method: method
            path: @path + path
            data: JSON.stringify(data)

    request: (method, cb, path, data) ->
        request @options(method, path, data), cb

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
        method = if @data._rev? then @db.put else @db.post
        method.call @db, @data._id, @data, (status, response) ->
            @data = response if status == 200
            cb(status, response)
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
