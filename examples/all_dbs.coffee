couch = require './lib/couchy'
db = couch.db 'mydb'
db.create()
db.get '_all_docs', (status, response) ->
    console.log response
