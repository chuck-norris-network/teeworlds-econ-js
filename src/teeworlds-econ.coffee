{ Socket } = require 'net'
{ EventEmitter } = require 'events'
split = require 'split'
splitText = require 'split-text'
{ parseWeapon } = require './utils'

class TeeworldsEcon extends EventEmitter

  constructor: (host, port, password) ->
    super

    @server = { host, port, password }

    @connection = null

  exec: (command) ->
    if !@connection
      @emit 'error', new Error 'Not connected'
      return

    @connection.write command + '\n'

  say: (message) ->
    # split long message to chunks
    chunks = message
      .split '\n'
      .map @escape
      .map (line) ->
        splitText line, 61
      .reduce (a, b) ->
        a.concat b

    # execute say command
    @exec "say \"#{chunk}\"" for chunk in chunks

  motd: (motd) ->
    @exec "sv_motd \"#{@escape motd}\""

  escape: (string) ->
    # escape quotes
    string = string.replace /"/g, '\\"'

    # escape line breaks
    string = string.replace /\n/g, '\\n'

    return string

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
      @emit 'pickup', matches[1], parseWeapon(matches[3])
      return

    # kill
    if matches = /^\[game\]: kill killer='[0-9-]+:([^']+)' victim='[0-9-]+:([^']+)' weapon=([0-9]+) special=[0-9]+$/.exec message
      return if matches[3] == '-3'
      @emit 'kill', matches[1], matches[2], parseWeapon(matches[3])
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
