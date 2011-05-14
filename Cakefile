require 'coffee-script'
{exec} = require 'child_process'
fs = require 'fs'

couchy = require './lib/couchy'

dbs = ['couchy-test-setup', 'couchy-test-seed', 'couchy-test-seed2', 'couchy-test-app']
test_cmd = 'vows --spec test/*'
noop = ->
destroyAll = ->
  for db in dbs
    couchy(db).destroy()

logTask = (msg) ->
  console.log "\n#{msg}"

option '-n', '--noclean', 'Do not destroy databases after test'

task 'docs', 'Generate documentation', (options) ->
  logTask "Generating documentation"
  exec 'docco lib/*.coffee'

task 'test', 'Run the test suites', (options) ->
  logTask "Running Tests"
  exec test_cmd, (err, stderr, stdout) ->
    console.error stderr
    console.log stdout
    destroyAll() unless options.noclean

task 'cleanup', 'Deletes the database', (options) ->
  logTask "Deleting test database"
  destroyAll()

console.log 'Couchy'
