{ formatClient, debug } = require '../utils'

# Flag capture messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
# @event enter { player, client }
module.exports = (econ, message) ->
  if matches = /^\[game\]: flag_capture player='([0-9]+):(.+?)'$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'capture'
    econ.emit 'capture', {
      player: matches[2]
      client: formatClient(econ.getClientInfo(parseInt(matches[1])))
    }
