{ formatClient, debug } = require '../utils'

# Flag grab messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
# @event flaggrab { player, client }
handleFlagGrabMessage = (econ, message) ->
  if matches = /^\[game\]: flag_grab player='([0-9]+):(.+?)'$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'flaggrab'
    econ.emit 'flaggrab', {
      player: matches[2]
      client: formatClient(econ.getClientInfo(parseInt(matches[1])))
    }

module.exports = handleFlagGrabMessage
