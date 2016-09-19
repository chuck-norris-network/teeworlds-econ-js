# Parse motd command output
#
# @private
# @param {String} output
# @return {String|null}
parseMotd = (output) ->
  motd = output
    .replace '[Console]: Value: ', ''
    .replace '\\n', '\n'
  return null if motd == ''
  return motd

module.exports = parseMotd
