require.paths.unshift(require('path').join(__dirname, '..', 'lib'))

require 'coffee-script'
vows = require 'vows'
assert = require 'assert'
couchy = require 'couchy'

db = couchy.db('couchy-test').create()

create_doc = -> couchy.doc db, {_id: 'myid', hello: 'hola', goodbye: 'adios'}

assertStatus = (code) ->
    (status, response) ->
        assert.equal status, code

vows.describe('Document is a Proxy').addBatch
    'when trying to access the data':
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
    'when trying to use its methods':
        topic: ->
            doc = create_doc()
            doc.save this.callback
        'it lets me save it': assertStatus(200)




.export(module)
