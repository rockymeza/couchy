require 'coffee-script'
request = require 'request'
vows = require 'vows'
assert = require 'assert'

couchy = require '../lib/couchy'

seed_db = couchy('couchy-test-seed')
setup_db = couchy('couchy-test-setup')

vows.describe('couchy')
.addBatch
  'database connection':
    'generic':
      topic: ->
        couchy('couchy-db-test')
      'returns a Database object': (db) ->
        assert.typeOf db, 'object'
        assert.instanceOf db, couchy.Database
      'standard host, port, etc.': (db) ->
        assert.equal db.url.hostname, 'localhost'
        assert.equal db.url.port, 5984
        assert.equal db.url.protocol, 'http:'
    'complex':
      topic: ->
        couchy('https://user:pass@example.com:1234/yourdb')
      'correct host, port, etc.': (db) ->
        assert.equal db.url.hostname, 'example.com'
        assert.equal db.url.port, 1234
        assert.equal db.url.protocol, 'https:'
        assert.equal db.url.auth, 'user:pass'
.addBatch
  'setup methods':
    '#exists':
      topic: ->
        couchy('couchy-nonexistent').exists this.callback
      'no request error': (err, bool) ->
        assert.isNull err
      'database does not exist': (err, bool) ->
        assert.isFalse bool
    '#create':
      topic: ->
        setup_db.create this.callback
      'no error': (bool) ->
        assert.isTrue bool
      'created a database':
        topic: ->
          setup_db.exists this.callback
        'that actually exists': (err, bool) ->
          assert.isTrue bool
.addBatch
  'seeding':
    topic: ->
      seed_db.create this.callback
    'saves the seed':
      topic: (bool) ->
        doc_cb = ->
          {foo: 'bar'}
        seed_db.seed doc_cb, this.callback
      'worked': (doc) ->
        assert.isObject doc
        assert.isNotNull doc._id
      'created a seed':
        topic: (doc) ->
          seed_db.query 'get', doc._id, this.callback
          undefined
        'no error': (err, res, body) ->
          assert.isNull err
        'that actually exists': (err, res, body) ->
          assert.equal res.statusCode, 200
        'that is what I said it would be': (err, res, body) ->
          assert.include body, 'foo'
          assert.equal body.foo, 'bar'
.export(module)
