require 'coffee-script'
couchy = require './lib/couchy'
{exec} = require 'child_process'

db = couchy('couchy-db-test')

task 'test', 'Run the test suites', (options) ->
  console.log "\nRunning Tests"
  db.destroy ->
    exec 'vows --spec test/*', (err, stderr, stdout) ->
      console.error err if err?
      console.error stderr
      console.log stdout

task 'cleanup', 'Deletes the database', (options) ->
  console.log "\nDeleting test database"
  db.destroy()

    
console.log 'Couchy'
