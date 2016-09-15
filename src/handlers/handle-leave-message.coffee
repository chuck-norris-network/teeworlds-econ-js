{ formatClient, debug } = require '../utils'

# Leave messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
# @event leave { player, client }
handleLeaveMessage = (econ, message) ->
  if matches = /^\[game\]: leave player='([0-9]+):(.+?)'$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'leave'
    econ.emit 'leave', {
      player: matches[2]
      client: formatClient(econ.getClientInfo(parseInt(matches[1])))
    }

module.exports = handleLeaveMessage
