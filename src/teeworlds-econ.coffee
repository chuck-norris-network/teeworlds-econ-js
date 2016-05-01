{ Socket } = require 'net'
{ EventEmitter } = require 'events'
split = require 'split'
splitText = require 'split-text'
{ parseWeapon, escape } = require './utils'

# Teeworlds external console wrapper class
#
class TeeworldsEcon extends EventEmitter

  # Constructor
  #
  # @param {String} host
  # @param {Integet} port
  # @param {String} pasword
  #
  constructor: (host, port, password) ->
    super

    @server = { host, port, password }

    @connection = null

  # Execute any command on server
  #
  # @param {String} command
  #
  exec: (command) ->
    if !@connection
      @emit 'error', new Error 'Not connected'
      return

    @connection.write command + '\n'

  # Say something to chat
  #
  # @param {String} message
  #
  say: (message) ->
    # split long message to chunks
    chunks = message
      .split '\n'
      .map escape
      .map (line) ->
        splitText line, 60
      .reduce (a, b) ->
        a.concat b

    # execute say command
    @exec "say \"#{chunk}\"" for chunk in chunks

  # Set server message of the day
  #
  # @param {String} message
  #
  motd: (message) ->
    @exec "sv_motd \"#{escape message}\""

  # Method for parsing incoming econ messages
  #
  # @param {String} message
  #
  handleMessage: (message) =>
    # chat enter
    if matches = /^\[chat\]: \*\*\* '([^']+)' entered and joined the.*/.exec message
      @emit 'enter', matches[1]
      return

    # chat leave
    if matches = /^\[chat\]: \*\*\* '([^']+)' has left the game.*/.exec message
      @emit 'leave', matches[1]
      return

    # chat message
    if matches = /^\[(teamchat|chat)\]: [0-9]+:[0-9-]+:([^:]+): (.*)$/.exec message
      @emit 'chat', matches[2], matches[3]
      return

    # pickup
    if matches = /^\[game\]: pickup player='[0-9-]+:([^']+)' item=(2|3)+\/([0-9\/]+)$/.exec message
      @emit 'pickup', matches[1], parseWeapon(parseInt(matches[3]))
      return

    # kill
    if matches = /^\[game\]: kill killer='[0-9-]+:([^']+)' victim='[0-9-]+:([^']+)' weapon=([-0-9]+) special=[0-9]+$/.exec message
      return if matches[3] == '-3'
      @emit 'kill', matches[1], matches[2], parseWeapon(parseInt(matches[3]))
      return

    # authentication request
    if message == 'Enter password:'
      @exec @server.password
      return

    # connected
    if message == 'Authentication successful. External console access granted.'
      @emit 'online'
      return

    # wrong password
    if /^Wrong password [0-9\/]+.$/.exec message
      @emit 'error', new Error "#{message} Disconnecting"
      return @disconnect()

    # authentication timeout
    if message == 'authentication timeout'
      @emit 'error', new Error 'Authentication timeout. Disconnecting'
      return @disconnect()

  # Connect to server econ
  #
  connect: () ->
    return if @connection

    @connection = new Socket()

    @connection
      .pipe split('\n\u0000\u0000')
      .on 'data', @handleMessage

    @connection.on 'error', (err) =>
      @emit 'error', err
    @connection.on 'close', @disconnect
    @connection.on 'end', @disconnect

    @connection.setKeepAlive true

    @connection.connect @server.port, @server.host

  # Disconnect from server
  #
  disconnect: () =>
    return if !@connection

    @connection.removeAllListeners 'data'
    @connection.removeAllListeners 'end'
    @connection.removeAllListeners 'error'
    @connection.destroy()
    @connection.unref()
    @connection = null
    @emit 'end'

module.exports = TeeworldsEcon
