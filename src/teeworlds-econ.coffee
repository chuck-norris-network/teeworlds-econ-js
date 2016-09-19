{ Socket } = require 'net'
{ EventEmitter } = require 'events'
{ EconError, EconConnectionError } = require './errors'
{ split, splitText, escape, parseStatus, parseTextValue, debug } = require './utils'
Transaction = require './transaction'
handlers = require './handlers'

# Teeworlds external console wrapper class
class TeeworldsEcon extends EventEmitter

  # @property {String}
  name: ''

  # @property {Array<String>}
  clients: []

  # Constructor
  #
  # @param {String} host
  # @param {Integer} port
  # @param {String} pasword
  constructor: (args...) ->
    super

    if typeof args[0] == 'object'
      { host, port, password } = args[0]
    else
      [ host, port, password ] = args
    throw new EconError('Undefined host') unless host
    throw new EconError('Undefined port') unless port
    throw new EconError('Undefined password') unless password
    @server = { host, port, password }

    @connection = null
    @connected = false

    @retryDelay = null
    @retryCount = null
    @retryTimer = null

    @resetTransactions()

    @resetHandlers()
    @addHandler handlers.handleEnterMessage
    @addHandler handlers.handleLeaveMessage
    @addHandler handlers.handlePickupMessage
    @addHandler handlers.handleChatMessage
    @addHandler handlers.handleKillMessage
    @addHandler handlers.handleFlagGrabMessage
    @addHandler handlers.handleFlagReturnMessage
    @addHandler handlers.handleCaptureMessage
    @addHandler handlers.handleNetBanMessage

  # Execute any command on server
  #
  # @param {String} command
  # @event error
  # @return {Promise}
  exec: (command, { timeout = 30000 } = {}) ->
    unless @isConnected(false)
      err = new EconConnectionError 'Not connected'
      debug.connection '%s:%s econ error: %s', @server.host, @server.port, err.message
      @emit 'error', err
      return Promise.reject err

    transaction = new Transaction command, { timeout }

    promise = new Promise (resolve, reject) =>
      transaction.on 'end', ({ id, result }) =>
        resolve result
        debug.connection '%s:%s %s transaction complete', @server.host, @server.port, id
        transaction.removeAllListeners 'end'
        transaction.removeAllListeners 'error'
        @removeTransaction transaction
      transaction.on 'error', (err) =>
        reject err
        debug.connection '%s:%s transaction error: %s', @server.host, @server.port, err.message
        transaction.removeAllListeners 'end'
        transaction.removeAllListeners 'error'
        @removeTransaction transaction

    @scheduleTransaction transaction

    return promise

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

  # Fetch players list
  #
  # @return {Promise}
  status: () ->
    @exec('status').then(parseStatus)

  # Get/set server message of the day
  #
  # @param {String} message
  svMotd: (message) ->
    return @exec "sv_motd \"#{escape message}\"" if message
    return @exec('sv_motd').then(parseTextValue)

  # Get/set server name
  #
  # @param {String} name
  svName: (name) ->
    return @exec "sv_name \"#{escape name}\"" if name
    return @exec('sv_name').then(parseTextValue)

  # Write to econ socket
  #
  # @param {String} message
  write: (message) ->
    return unless @connection and @connection.writable
    debug.connection 'writing to %s:%s econ: %s', @server.host, @server.port, message
    @connection.write message + '\n'

  # Add messages handler
  #
  # @param {Function} handler
  addHandler: (handler) ->
    @handlers.push handler

  # Remove messages handler
  #
  # @param {Function} handler
  removeHandler: (handler) ->
    index = @handlers.find (item) -> handler == item
    @handlers.splice index, 1 unless index == -1

  # Remove all messages handlers
  resetHandlers: () ->
    @handlers = []

  # Schedule transaction
  #
  # @private
  # @param {Function} transaction
  scheduleTransaction: (transaction) ->
    @transactions.push transaction
    @write transaction.getCommand()

  # Remove transaction from queue
  #
  # @private
  # @param {Function} transaction
  removeTransaction: (transaction) ->
    index = @transactions.find (item) -> transaction == item
    @transactions.splice index, 1 unless index == -1

  # Clean transactions
  #
  # @private
  resetTransactions: () ->
    @transactions = []

  # Method for parsing incoming econ messages
  #
  # @private
  # @param {String} message
  # @event online
  # @event reconnected
  # @event error
  # @event end
  handleMessage: (message) =>
    debug.connection 'reading from %s:%s econ: %s', @server.host, @server.port, message

    # client connection
    do (message) =>
      if matches = /^\[server\]: player has entered the game. ClientID=([0-9]+) addr=(.+?):([0-9]+)$/.exec message
        cid = parseInt(matches[1])
        client = "#{matches[2]}:#{matches[3]}"
        debug.connection 'new client (%s) with ip:port %s on %s:%s ', cid, client, @server.host, @server.port
        @setClientInfo cid, client

    # client disconnect
    do (message) =>
      if matches = /^\[game\]: leave player='([0-9]+):.*'$/.exec message
        cid = parseInt(matches[1])
        debug.connection 'client disconnect (%s) on %s:%s ', cid, @server.host, @server.port
        @removeClientInfo cid

    # authentication request
    if message == 'Enter password:'
      debug.connection '%s:%s password request', @server.host, @server.port
      @write @server.password
      return

    # connected
    if message == 'Authentication successful. External console access granted.'
      Promise.all([
        @svName()
        @status()
      ])
      .then ([name, status]) =>
        @name = name
        @setClientInfo player.cid, player.client for player in status if status

        unless @connected
          @connected = true
          debug.connection '%s:%s connected', @server.host, @server.port
          @emit 'online'
        else
          debug.connection '%s:%s reconnected', @server.host, @server.port
          @emit 'reconnected'
      .catch (err) ->
        debug.connection '%s:%s econ error: %s', @server.host, @server.port, err.message
        @emit 'error', err

      return

    # wrong password
    if /^Wrong password [0-9\/]+.$/.exec message
      err = new EconConnectionError "#{message} Disconnecting"
      debug.connection '%s:%s econ error: %s', @server.host, @server.port, err.message
      @emit 'error', err
      @disconnect()
      @emit 'end'
      return

    # authentication timeout
    if message == 'authentication timeout'
      err = new EconConnectionError 'Authentication timeout. Disconnecting'
      debug.connection '%s:%s econ error: %s', @server.host, @server.port, err.message
      @emit 'error', err
      @disconnect()
      @emit 'end'
      return

    # pass message to transaction handlers
    @transactions.forEach (transaction) -> transaction.handleMessage message

    # do not execute handlers while not connected
    return unless @isConnected()

    # execute all event handlers sequentaly
    for handler in @handlers
      result = handler.call @, @, message
      break if result == false

  # Assign info for client with specified ID
  #
  # @private
  # @param {Integer} cid
  # @param {String} client
  # @return {String}
  setClientInfo: (cid, client) ->
    @clients[cid] = client

  # Remove client info from table
  #
  # @private
  # @param {Integer} cid
  removeClientInfo: (cid) ->
    delete @clients[cid]

  # Return available info for client with specified ID
  #
  # @param {Integer} cid
  # @return {Object}
  getClientInfo: (cid) ->
    return @clients[cid] ? null

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
      .pipe split(/\r?\n\u0000*/)
      .on 'data', @handleMessage

    @connection.on 'error', (err) =>
      debug.connection '%s:%s connection error: %s', @server.host, @server.port, err.message
      @emit 'error', err
    @connection.on 'close', @reconnect
    @connection.on 'end', @reconnect

    @connection.setKeepAlive true

    debug.connection 'connecting to %s:%s', @server.host, @server.port

    @connection.connect @server.port, @server.host

  # Reconnect on connection lost
  #
  # @private
  # @event end
  # @event reconnect
  reconnect: () =>
    return if @retryTimer

    debug.connection 'reconnecting to %s:%s', @server.host, @server.port

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

    debug.connection 'disconnecting from %s:%s', @server.host, @server.port

    @connection.removeAllListeners 'data'
    @connection.removeAllListeners 'end'
    @connection.removeAllListeners 'error'
    @connection.destroy()
    @connection.unref()
    @connection = null

  # Check connection status
  #
  # @param {Boolean} initialized
  # @return {Boolean}
  isConnected: (initialized = true) ->
    return @connection and @connection.writable and (!initialized or @connected)

module.exports = TeeworldsEcon
