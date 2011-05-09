                          _           
      ___ ___  _   _  ___| |__  _   _ 
     / __/ _ \| | | |/ __| '_ \| | | |
    | (_| (_) | |_| | (__| | | | |_| |
     \___\___/ \__,_|\___|_| |_|\__, |
                                |___/ 

Couchy is a CouchDB wrapper for node and CoffeeScript.

    db = require('couchy')('mydb')

    db.view path: 'app/things', (err, res) ->
      console.error err if err?
      res.forEach (thing) ->
        console.log thing
