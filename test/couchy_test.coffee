require 'coffee-script'
request = require 'request'
vows = require 'vows'
assert = require 'assert'

couchy = require '../lib/couchy'

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
        couchy('couchy-db-test').create this.callback
      'no error': (bool) ->
        assert.isTrue bool
      'created a database':
        topic: ->
          couchy('couchy-db-test').exists this.callback
        'that actually exists': (err, bool) ->
          assert.isTrue bool
      teardown: ->
        couchy('couchy-db-test').destroy()
.export(module)
