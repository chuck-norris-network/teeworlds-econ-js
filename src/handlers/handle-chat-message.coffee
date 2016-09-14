{ formatClient, debug } = require '../utils'

# Chat messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
# @event chat { type, player, message, team, client }
module.exports = (econ, message) ->
  # player chat message
  if matches = /^\[(teamchat|chat)\]: ([0-9]+):([0-9-]+):(.+?): (.*)$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'chat'
    econ.emit 'chat', {
      type: matches[1]
      player: matches[4]
      message: matches[5]
      team: parseInt(matches[3])
      client: formatClient(econ.getClientInfo(parseInt(matches[2])))
    }

  # server chat message
  if matches = /^\[chat\]: \*\*\* (.*)$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'chat'
    econ.emit 'chat', {
      type: 'server'
      player: null
      message: matches[1]
      team: null
      client: null
    }
