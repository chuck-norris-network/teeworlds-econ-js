{ formatClient, debug, parseWeapon } = require '../utils'

# Pickup messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
# @event enter { player, weapon, client }
module.exports = (econ, message) ->
  if matches = /^\[game\]: pickup player='([0-9]+):(.+?)' item=(2|3)+\/([0-9]+)$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'pickup'
    econ.emit 'pickup', {
      player: matches[2]
      weapon: parseWeapon(parseInt(matches[4]))
      client: formatClient(econ.getClientInfo(parseInt(matches[1])))
    }
