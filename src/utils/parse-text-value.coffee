# Parse text value command output
#
# @private
# @param {String} output
# @return {String|null}
parseTextValue = (output) ->
  text = output
    .replace '[Console]: Value: ', ''
    .replace '\\n', '\n'
  return null if text == ''
  return text

module.exports = parseTextValue
