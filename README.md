# couchy

couchy is a CouchDB wrapper for node and CoffeeScript.  couchy tries to have a developer-friendly, but minimal API.  I plan to make possible everything you can do with CouchDB, and add some helpers that I find useful.

## Connect to Database
    db = require('couchy')('mydb')

## Setup and Destroy
`db.create([callback(err, created:bool)])`

```coffee-script
db.create (err, bool) ->
  console.log 'created mydb'
```

`db.destroy([callback(error, response, body])`

```coffee-script
db.destroy (err) ->
  console.log 'destroyed mydb'
```

## Queries
The query method has a flexible invocation.  All arguments after method are optional, but any of them can be included, so long as they remain in order.  Instead of having to do something like this, `db.query 'head', '', {}, ->`, you can simplify your call to `db.query 'head', ->`.

`db.query(method:string, [path:string], [data:object], [callback(error, response, body)])`

```coffee-script
db.query 'get', 'someid', (err, res, body) ->
  console.log body

db.query 'post', 'someid', {foo: bar}, (err, res, body) ->
  console.log body
```

## Views
`db.view(path:string, [callback])`

```coffee-script
db.view 'app/things', (err, res) ->
  res.forEach (thing) ->
    console.log thing
```

`db.view(path:string, options:object, [callback])`
    
```coffee-script
db.view 'app/thingsByName', {key: 'Foo'}, (err, res) ->
  res.forEach (thing) ->
    console.log thing
```

## Seeding
This is mainly for creating test data.  It takes a callback would should return a document.

`db.seed(doc_callback, [callback(error, docs, body)])`

```coffee-script
db.seed ->
  type: 'thing', name: 'Foo', bar: 'Bar', string: @string(), number: @number()
```

This works for creating a document in the database.  What if I need a bunch?

`db.seed([times], doc_callback, [callback(error, docs, body)])`

```coffee-script
db.seed 10, ->
  type: 'thing', name: 'Foo', string: @string(15), number: @number(144, 2), thing: @pick(['this', 'that'])
```
### Seeding Helpers

- `number(max = 100, precision = 0)` -- creates a random number and rounds to a precision
- `string(length = 10)` -- creates a random string using charcodes 65-122 (A-z)
- `pick(choices)` -- picks randomly from an array

## CouchApp -- sort of
```coffee-script
app = db.app

app.views.thingsByName = (doc) ->
  if doc.type == "thing"
    emit(doc.name, doc)

app.push()
```

## Module Exports
The couchy module exports a function that can be used to create a Database connection.  It also exports the Database and Seed classes, which can be used for type checking.
