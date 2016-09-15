# Escape econ command
#
# @private
# @param {String} input
# @return {String}
escape = (input) ->
  # escape backslashes
  string = input.replace /\\/g, '\\\\'

  # escape quotes
  string = string.replace /"/g, '\\"'

  # escape line breaks
  string = string.replace /\n/g, '\\n'

  return string

module.exports = escape
