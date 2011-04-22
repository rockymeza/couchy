http = require 'http'
Proxy = require 'node-proxy'

request = (options, cb) ->
    response = ''
    req = http.request options, (res) ->
        res.setEncoding('utf8')
        res.on 'data', (chunk) ->
            response += chunk
        res.on 'end', ->
            response = JSON.parse(response) if response
            cb res.statusCode, response if cb?

    req.write(options.data, 'utf8') if options.data?
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
            cb(status == 200)

    create: ->
        @exists (bool) =>
            @put '' if bool

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

# Document class
class Document
    constructor: (@db, @data) ->
    get: (rec, name) ->
        @data[name]
    set: (rec, name, value) ->
        @data[name] = value
    enumerate: ->
        Object.keys(@data)
    has: (name) ->
        name
    delete: (name) ->
        false
    fix: ->
        undefined

# exports
exports.db = (database, options) ->
    new Database database, options
exports.Document = Document
exports.doc = (database, data) ->
    Proxy.create(new Document(database, data))
