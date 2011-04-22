require 'coffee-script'
Proxy = require 'node-proxy'
couchy = require './lib/couchy'

db = couchy.db('node-couch')
doc = couchy.doc(db, {hello: 'world'})

console.log doc.hello
