{ debug } = require '../utils'

# Network ban messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
# @event enter { ip, reason, minutes, life }
module.exports = (econ, message) ->
  if matches = /^\[net_ban\]: '([^']+)' banned for ([0-9]+) minutes \((.+?)\)$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'netban'
    econ.emit 'netban', {
      ip: matches[1]
      reason: matches[3]
      minutes: matches[2]
      life: false
    }

  if matches = /^\[net_ban\]: '([^']+)' banned for life \((.+?)\)$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'netban'
    econ.emit 'netban', {
      ip: matches[1]
      reason: matches[2]
      minutes: null
      life: true
    }
