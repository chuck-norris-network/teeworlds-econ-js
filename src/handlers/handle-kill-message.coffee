{ debug, parseWeapon } = require '../utils'

# Kill messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
# @event kill { killer, victim, weapon, killerClient, victimClient }
handleKillMessage = (econ, message) ->
  if matches = /^\[game\]: kill killer='([0-9]+):(.+?)' victim='([0-9]+)+:(.+?)' weapon=([0-9-]+) special=[0-9]+$/.exec message
    return if matches[5] == '-3'
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'kill'
    econ.emit 'kill', {
      killer: matches[2]
      victim: matches[4]
      weapon: parseWeapon(parseInt(matches[5]))
      killerClient: econ.getClientInfo(parseInt(matches[1]))
      victimClient: econ.getClientInfo(parseInt(matches[3]))
    }

module.exports = handleKillMessage
