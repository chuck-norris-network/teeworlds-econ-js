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
    if !@connection
      @emit 'error', new Error 'Not connected'
      return

    @connection.write command + '\n'

  # Say something to chat
  #
  # @param {String} message
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
  motd: (message) ->
    @exec "sv_motd \"#{escape message}\""

  # Method for parsing incoming econ messages
  #
  # @param {String} message
  # @event enter
  # @event leave
  # @event chat
  # @event pickup
  # @event kill
  # @event online
  # @event reconnected
  # @event error
  # @event end
  handleMessage: (message) =>
    # client connection
    if matches = /^\[server\]: player has entered the game. ClientID=[0-9]+ addr=([0-9a-f.:]+):[0-9]+$/.exec message
      @lastClientIp = matches[1]
      return

    # chat enter
    if matches = /^\[chat\]: \*\*\* '([^']+)' entered and joined the (.*)$/.exec message
      @emit 'enter', matches[1], matches[2], @lastClientIp
      @lastClientIp = null
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
  #   econ.connect({ retryDelay: 5000, retryCount: -1 })
  #
  # @param {Object} connectionParams
  # @event error
  connect: (connectionParams = {}) ->
    return if @connection

    @retryDelay = if connectionParams.retryDelay then connectionParams.retryDelay else 5000
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
  # event end
  # event reconnect
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

module.exports = TeeworldsEcon
