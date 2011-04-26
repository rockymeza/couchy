require.paths.unshift(require('path').join(__dirname, '..', 'lib'))
require 'coffee-script'
vows = require 'vows'
assert = require 'assert'
couchy = require 'couchy'
# https://github.com/mikeal/request - saw this there, modified for my use
rand = -> Math.floor(Math.random()*100000000).toString()

db = couchy.db('couchy-test').create()
create_doc = -> couchy.doc db, {_id: rand(), hello: 'hola', goodbye: 'adios'}

assertStatus = (code ...) ->
    (err, res, body) ->
        assert.include code, res.statusCode

vows.describe('Document Proxy').addBatch
    'when using the proxy':
        topic: create_doc
        'it lets me get data':
            topic: create_doc
            'object-style': (doc) ->
                assert.equal doc.hello, 'hola'
            'array-style': (doc) ->
                assert.equal doc['goodbye'], 'adios'
        
        'it lets me set data':
            topic: create_doc
            'object-style': (doc) ->
                doc.hello = 'bonjour'
                assert.equal doc.hello, 'bonjour'
            'array-style': (doc) ->
                doc['goodbye'] = 'au revoir'
                assert.equal doc['goodbye'], 'au revoir'

        'it lets me loop over the data': (doc) ->
            test_length = 0
            for key in doc
                assert.isNotNull doc[key]
                assert.equal doc[key], false
                ++test_length

            assert.equal test_length, 3

        'it lets me check existence of a key':
            topic: create_doc
            'that exists': (doc) ->
                assert.equal 'hello' of doc, true
            'that does not exist': (doc) ->
                assert.equal 'nonexistent key' of doc, false

        'it lets me delete keys':
            topic: create_doc
            'delete huzzah': (doc) ->
                delete doc.hello
                assert.equal doc.hello, undefined
.export(module)
vows.describe('Document model').addBatch
    'when using the methods':
        topic: ->
            doc = create_doc()
            doc.save this.callback
            undefined
        'assert no errors': (err, res, body) ->
            assert.isNull err
        'assert status': assertStatus(201) # created
.export(module)
