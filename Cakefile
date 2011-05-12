require 'coffee-script'
{exec} = require 'child_process'
fs = require 'fs'

couchy = require './lib/couchy'

noop = ->
destroyAll = ->
  couchy('couchy-test-seed').destroy()
  couchy('couchy-test-seed2').destroy()
  couchy('couchy-test-setup').destroy()

logTask = (msg) ->
  console.log "\n#{msg}"

option '-n', '--noclean', 'Do not destroy databases after test'

task 'docs', 'Generate documentation', (options) ->
  logTask "Generating documentation"
  exec 'docco lib/*.coffee'


task 'test', 'Run the test suites', (options) ->
  logTask "Running Tests"
  exec 'vows --spec test/*', (err, stderr, stdout) ->
    console.error err if err?
    console.error stderr
    console.log stdout
    destroyAll() unless options.noclean

task 'cleanup', 'Deletes the database', (options) ->
  logTask "Deleting test database"
  destroyAll()

    
console.log 'Couchy'
