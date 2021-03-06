{ debug } = require '../utils'

# Enter messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
# @event enter { player, team, client }
handleEnterMessage = (econ, message) ->
  if matches = /^\[game\]: team_join player='([0-9]+):(.+?)' team=([0-9-]+)$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'enter'
    econ.emit 'enter', {
      player: matches[2]
      team: parseInt(matches[3])
      client: econ.getClientInfo(parseInt(matches[1]))
    }

module.exports = handleEnterMessage
