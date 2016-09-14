{ debug } = require '../utils'

# Flag return messages handler
#
# @param {TeeworldsEcon} econ
# @param {String} message
module.exports = (econ, message) ->
  if /^\[game\]: flag_return$/.exec message
    debug.events '%s:%s econ %s event', econ.server.host, econ.server.port, 'flagreturn'
    econ.emit 'flagreturn', {}
