require 'coffee-script'
couchy = require './lib/couchy'
{exec} = require 'child_process'

noop = ->

destroyAll = ->
  couchy('couchy-test-seed').destroy()
  couchy('couchy-test-setup').destroy()

task 'test', 'Run the test suites', (options) ->
  console.log "\nRunning Tests"
  exec 'vows --spec test/*', (err, stderr, stdout) ->
    console.error err if err?
    console.error stderr
    console.log stdout
    destroyAll()

task 'cleanup', 'Deletes the database', (options) ->
  console.log "\nDeleting test database"
  destroyAll()

    
console.log 'Couchy'
