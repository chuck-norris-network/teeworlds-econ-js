{ Socket } = require 'net'
{ EventEmitter } = require 'events'
split = require 'split'
splitText = require 'split-text'
{ parseWeapon, escape } = require './utils'

# Teeworlds external console wrapper class
class TeeworldsEcon extends EventEmitter

  # Constructor
  #
  # @param {String} host
  # @param {Integer} port
  # @param {String} pasword
  constructor: (host, port, password) ->
    super

    @server = { host, port, password }

    @connection = null
    @connected = false

    @retryDelay = null
    @retryCount = null
    @retryTimer = null

    @lastClientIp = null

  # Execute any command on server
  #
  # @param {String} command
  # @event error
  exec: (command) ->
    unless @isConnected()
      @emit 'error', new Error 'Not connected'
      return

    @write command

  # Say something to chat
  #
  # @param {String} message
  # @param {Integer} limit max line length
  say: (message, limit = 256) ->
    # maximum line length = 256
    limit = 256 if limit > 256
    # split long message to chunks
    chunks = message
      .split '\n'
      .map escape
      .map (line) ->
        splitText line, limit
      .reduce (a, b) ->
        a.concat b

    # execute say command
    @exec "say \"#{chunk}\"" for chunk in chunks

  # Set server message of the day
  #
  # @param {String} message
  motd: (message) ->
    @exec "sv_motd \"#{escape message}\""

  # Write to econ socket
  #
  # @param {String} string string
  write: (string) ->
    return unless @connection and @connection.writable
    @connection.write string + '\n'

  # Method for parsing incoming econ messages
  #
  # @private
  # @param {String} message
  # @event enter { player, team, ip }
  # @event leave { player }
  # @event capture { flag, player, time }
  # @event chat { type, player, message }
  # @event pickup { player, weapon }
  # @event kill { killer, victim, weapon }
  # @event online
  # @event reconnected
  # @event error
  # @event end
  handleMessage: (message) =>
    # client connection
    if matches = /^\[server\]: player has entered the game. ClientID=[0-9]+ addr=([0-9a-f.:]+):[0-9]+$/.exec message
      @lastClientIp = matches[1]
      return

    # enter
    if matches = /^\[chat\]: \*\*\* '([^']+)' entered and joined the (.*)$/.exec message
      @emit 'enter', {
        player: matches[1]
        team: matches[2]
        ip: @lastClientIp
      }
      @lastClientIp = null

    # leave
    if matches = /^\[chat\]: \*\*\* '([^']+)' has left the game.*/.exec message
      @emit 'leave', {
        player: matches[1]
      }

    # capture
    if matches = /^\[chat\]: \*\*\* The ([^ ]+) flag was captured by '([^']+)' \(([0-9.]+) seconds\)$/.exec message
      @emit 'capture', {
        flag: matches[1]
        player: matches[2]
        time: parseFloat(matches[3]) * 1000
      }

    # chat message
    if matches = /^\[(teamchat|chat)\]: [0-9]+:[0-9-]+:([^:]+): (.*)$/.exec message
      @emit 'chat', {
        type: matches[1]
        player: matches[2]
        message: matches[3]
      }
      return

    # server chat message
    if matches = /^\[chat\]: \*\*\* (.*)$/.exec message
      @emit 'chat', {
        type: 'server'
        player: null
        message: matches[1]
      }
      return

    # pickup
    if matches = /^\[game\]: pickup player='[0-9-]+:([^']+)' item=(2|3)+\/([0-9\/]+)$/.exec message
      @emit 'pickup', {
        player: matches[1]
        weapon: parseWeapon(parseInt(matches[3]))
      }
      return

    # flag grab
    if matches = /^\[game\]: flag_grab player='[0-9-]+:([^']+)'$/.exec message
      @emit 'flaggrab', {
        player: matches[1]
      }
      return

    # flag return
    if matches = /^\[game\]: flag_return$/.exec message
      @emit 'flagreturn', {}
      return

    # kill
    if matches = /^\[game\]: kill killer='[0-9-]+:([^']+)' victim='[0-9-]+:([^']+)' weapon=([-0-9]+) special=[0-9]+$/.exec message
      return if matches[3] == '-3'
      @emit 'kill', {
        killer: matches[1]
        victim: matches[2]
        weapon: parseWeapon(parseInt(matches[3]))
      }
      return

    # authentication request
    if message == 'Enter password:'
      @write @server.password
      return

    # connected
    if message == 'Authentication successful. External console access granted.'
      unless @connected
        @connected = true
        @emit 'online'
      else
        @emit 'reconnected'
      return

    # wrong password
    if /^Wrong password [0-9\/]+.$/.exec message
      @emit 'error', new Error "#{message} Disconnecting"
      @disconnect()
      @emit 'end'
      return

    # authentication timeout
    if message == 'authentication timeout'
      @emit 'error', new Error 'Authentication timeout. Disconnecting'
      @disconnect()
      @emit 'end'
      return

  # Connect to server econ
  #
  # @example Set connection params
  #   econ.connect({ retryDelay: 30000, retryCount: -1 })
  #
  # @param {Object} connectionParams
  # @event error
  connect: (connectionParams = {}) ->
    return if @connection

    @retryDelay = if connectionParams.retryDelay then connectionParams.retryDelay else 30000
    @retryCount = if connectionParams.retryCount then connectionParams.retryCount else -1

    @connection = new Socket()

    @connection
      .pipe split(/(\r?\n\u0000{0,})/)
      .on 'data', @handleMessage

    @connection.on 'error', (err) =>
      @emit 'error', err
    @connection.on 'close', @reconnect
    @connection.on 'end', @reconnect

    @connection.setKeepAlive true

    @connection.connect @server.port, @server.host

  # Reconnect on connection lost
  #
  # @private
  # @event end
  # @event reconnect
  reconnect: () =>
    return if @retryTimer

    if @retryCount == 0
      @disconnect()
      @emit 'end'
      return
    @retryCount-- if @retryCount > 0

    @emit 'reconnect'
    @retryTimer = setTimeout () =>
      @retryTimer = null
      @disconnect()
      @connect({ @retryDelay, @retryCount })
    , @retryDelay

  # Disconnect from server
  disconnect: () =>
    return if !@connection

    @connection.removeAllListeners 'data'
    @connection.removeAllListeners 'end'
    @connection.removeAllListeners 'error'
    @connection.destroy()
    @connection.unref()
    @connection = null

  # Check connection status
  #
  # @return {Boolean} is connected/disconnected
  isConnected: () ->
    return @connection and @connection.writable and @connected

module.exports = TeeworldsEcon
