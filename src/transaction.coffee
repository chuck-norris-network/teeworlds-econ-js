{ generateTransactionId } = require './utils'
{ EventEmitter } = require 'events'
{ EconError } = require './errors'

# Econ transactions helper
# @private
class Transaction extends EventEmitter

  # Econ transactions helper constructor
  #
  # @param {String} command
  # @param {Object} { timeout }
  constructor: (command, { timeout }) ->
    @command = command

    @data = []

    @started = false
    @done = false

    @id = generateTransactionId()
    @beginRe = new RegExp "^\\[Console\\]: begin #{@id}$"
    @endRe = new RegExp "^\\[Console\\]: end #{@id}$"

    setTimeout (=> @emit 'error', new EconError('Transaction timeout')), timeout

  # Prepare command with begin/end parts
  #
  # @return {String}
  getCommand: () ->
    "echo \"begin #{@id}\"; #{@command}; echo \"end #{@id}\""

  # Messages handler
  #
  # @param {String} message
  # @event begin
  # @event end
  handleMessage: (message) ->
    if @beginRe.test message
      @started = true
      @emit 'begin', { @id }
      return

    if @endRe.test message
      @done = true
      @emit 'end', { id: @id, result: @data.join('\n') }
      return

    @data.push message if @started

module.exports = Transaction
