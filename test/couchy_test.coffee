require 'coffee-script'
request = require 'request'
vows = require 'vows'
assert = require 'assert'

couchy = require '../lib/couchy'

setup_db = couchy('couchy-test-setup')
seed_db = couchy('couchy-test-seed')
seed_db2 = couchy('couchy-test-seed2')
app_db = couchy('couchy-test-app')

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
    'simple seed':
      topic: (bool) ->
        doc_cb = ->
          {foo: 'bar'}
        seed_db.seed doc_cb, this.callback
      'saved': (err, docs, res) ->
        assert.isArray docs
        assert.isNotNull res[0].id
      'created a seed':
        topic: (docs, res) ->
          seed_db.query 'get', res[0].id, this.callback
          undefined
        'no error': (err, res, body) ->
          assert.isNull err
        'that actually exists': (err, res, body) ->
          assert.equal res.statusCode, 200
        'that is what I said it would be': (err, res, body) ->
          assert.include body, 'foo'
          assert.equal body.foo, 'bar'
    'complex seed':
      topic: (bool) ->
        doc_cb = ->
          {foo: 'bar', number: @number()}
        seed_db.seed doc_cb, this.callback
      'saved': (err, docs, res) ->
        assert.isArray docs
        assert.isNotNull res[0].id
      'created a seed':
        topic: (docs, res) ->
          seed_db.query 'get', res[0].id, this.callback
          undefined
        'no error': (err, res, body) ->
          assert.isNull err
        'that actually exists': (err, res, body) ->
          assert.equal res.statusCode, 200
        'that is what I said it would be': (err, res, body) ->
          assert.include body, 'foo'
          assert.equal body.foo, 'bar'
    'invocation errors':
      'should not exist': ->
        assert.doesNotThrow (-> seed_db.seed(-> {})), Error
        assert.doesNotThrow (-> seed_db.seed(10, -> {})), Error
        assert.doesNotThrow (-> seed_db.seed((-> {}), (->))), Error
        assert.throws (-> seed_db.seed(10)), Error
  'multiple seed':
    topic: ->
      seed_db2.create this.callback
    '15 seed':
      topic: (bool) ->
        doc_cb = ->
          {type: 'this', string: @string(15), money: @number(15, 2)}
        seed_db2.seed 15, doc_cb, this.callback
      'created seeds':
        topic: ->
          seed_db2.query 'get', '_all_docs', this.callback
          undefined
        '15 of them': (err, res, body) ->
          assert.equal body.rows.length, 15
  'seed helpers':
    topic: ->
      new couchy.Seed()
    'number': (seed) ->
      assert.isNumber seed.number()
    'string': (seed) ->
      assert.isString seed.string()

      assert.equal seed.string(15).length, 15
    'pick': (seed) ->
      choices = ['Foo', 'Bar']
      assert.include choices, seed.pick(choices)
.addBatch
  'apps':
    topic: ->
      cb = this.callback
      app_db.create ->
        app_db.seed 5, (-> type: 'thing', name: @string()), ->
          app_db.seed 3, (-> type: 'notThings', number: @number()), cb
      undefined
    'noninterference': ->
      app1 = app_db.app('app1')
      app2 = app_db.app('app2')

      app1.views.foo = 'bar'
      assert.isUndefined app2.views.foo
    'basic app':
      topic: app_db.app('testApp')
      'toJSON': (app) ->
        to_json = app.toJSON()
        assert.isObject to_json
        for i in ['views', 'updates', 'shows', 'lists']
          assert.include to_json, i
      'toString':
        topic: app_db.app('toStringApp')
        'simple': (app) ->
          assert.equal app.toString(), '{"views":{},"updates":{},"shows":{},"lists":{}}'
        'function': (app) ->
          assert.equal JSON.stringify(app.prepare({a: ->})), JSON.stringify({a: (->).toString()})
        'nested objects': (app) ->
          assert.equal JSON.stringify(app.prepare({a: {b: ->}})), JSON.stringify({a: {b: (->).toString()}})
    'creating design document':
      topic: app_db.app('test2App')
      'add view': (app2) ->
        app2.views.thingsByName =
          map: (doc) ->
            if doc.type == 'thing'
              emit(doc.name, doc)
        to_json = app2.toJSON()
        assert.include to_json.views, 'thingsByName'
        assert.include to_json.views.thingsByName, 'map'
        assert.isFunction to_json.views.thingsByName.map
      'push':
        topic: (app2) ->
          app2.push this.callback
          undefined
        'no errors': (err, res, body) ->
          assert.isNull err
        'is it there':
          topic: ->
            app_db.query 'get', '_design/test2App/_view/thingsByName', this.callback
            undefined
          'there is something': (err, res, body) ->
            assert.isNull err
            assert.equal body.total_rows, 5


.export(module)
