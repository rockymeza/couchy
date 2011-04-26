require.paths.unshift(require('path').join(__dirname, '..', 'lib'))
require 'coffee-script'
request = require 'request'
vows = require 'vows'
assert = require 'assert'
couchy = require 'couchy'
# https://github.com/mikeal/request - saw this there, modified for my use
makeId = -> Math.floor(Math.random()*100000000).toString()
assertStatus = (code ...) ->
    (err, res, body) ->
        assert.include code, res.statusCode

vows.describe('Database Class')
.addBatch
    'request methods':
        topic: couchy.db('couchy-db-test')
        '#exists':
            'returns db object for chainability': (db) ->
                return_value = db.exists ->
                assert.equal return_value, db
        '#create':
            'returns db object for chainability': (db) ->
                return_value = db.create()
                assert.equal return_value, db
            '#delete': (db) ->
                db.delete ->
                    request {uri: 'http://localhost:5984/_add_dbs'}, (err, res, body) ->
                        assert.equal body.indexOf('couchy-db-test'), -1

.export(module)

db = couchy.db('couchy-doc-test').create()
create_doc = -> couchy.doc db, {_id: makeId(), hello: 'hola', goodbye: 'adios'}

vows.describe('Document Class')
.addBatch
    'Harmony Proxy':
        '#get':
            topic: create_doc
            'object-style': (doc) ->
                assert.equal doc.hello, 'hola'
            'array-style': (doc) ->
                assert.equal doc['goodbye'], 'adios'
        
        '#set':
            topic: create_doc
            'object-style': (doc) ->
                doc.hello = 'bonjour'
                assert.equal doc.hello, 'bonjour'
            'array-style': (doc) ->
                doc['goodbye'] = 'au revoir'
                assert.equal doc['goodbye'], 'au revoir'

        '#enumerate':
            topic: create_doc
            'count all elements': (doc) ->
                test_length = 0
                for key in doc
                    assert.isNotNull doc[key]
                    assert.equal doc[key], false
                    ++test_length

                assert.equal test_length, 3

        '#has':
            topic: create_doc
            'exists': (doc) ->
                assert.equal 'hello' of doc, true
            'does not exist': (doc) ->
                assert.equal 'nonexistent key' of doc, false

        '#delete':
            topic: create_doc
            'delete huzzah': (doc) ->
                delete doc.hello
                assert.equal doc.hello, undefined
.addBatch
    'Model methods':
        '#save':
            topic: ->
                doc = create_doc()
                doc.save this.callback
                undefined # force asynchronous testing
            'no errors': (err, res, body) ->
                assert.isNull err
            'status': assertStatus(201) # created
.export(module)
