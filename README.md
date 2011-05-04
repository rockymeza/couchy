couchy
======

Couchy is a CouchDB wrapper for node.


Connections
-----------

Connections are the closest thing to pure Couch.  They are not live connections of course, but they provide convenience request methods such as get and post.

    connection = couchy.connection()

    connection.get '_all_dbs', (error, response, body) ->
        console.log body


Databases
---------

Database extends from Connections.  Databases can have some more methods, such as exists and create.

    db = couchy.db('mydb')
    db.exists (yes) ->
        console.log yes
