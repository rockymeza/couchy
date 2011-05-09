                          _           
      ___ ___  _   _  ___| |__  _   _ 
     / __/ _ \| | | |/ __| '_ \| | | |
    | (_| (_) | |_| | (__| | | | |_| |
     \___\___/ \__,_|\___|_| |_|\__, |
                                |___/ 

Couchy is a CouchDB wrapper for node and CoffeeScript.

Connect to Database
-------------------
    db = require('couchy')('mydb')

Setup and Destroy
-----------------
`db.create([callback])`

    db.create (bool) ->
      console.log 'created mydb'

`db.destroy([callback])`

    db.destroy ->
      console.log 'destroyed mydb'

Queries
-------
`db.query(method:string, [path:string, data:object], [callback(error, response, body)])`

    db.query 'get', 'someid', (err, res, body) ->
      console.log body

    db.query 'post', 'someid', {foo: bar}, (err, res, body) ->
      console.log body

Views
-----
`db.view(path:string, callback)`

    db.view 'app/things', (err, res) ->
      res.forEach (thing) ->
        console.log thing

`db.view(path:string, options:object, callback)`
    
    db.view 'app/thingsByName', {key: 'Foo'}, (err, res) ->
      res.forEach (thing) ->
        console.log thing

Seeding
-------
`db.seed(callback)`

    db.seed ->
      type: 'thing', name: 'Foo', bar: 'Bar', date: @randDate(), number: @rand()
