# Escape econ command
#
# @param {String} input
# @return {String}
module.exports = (input) ->
  # escape backslashes
  string = input.replace /\\/g, '\\\\'

  # escape quotes
  string = string.replace /"/g, '\\"'

  # escape line breaks
  string = string.replace /\n/g, '\\n'

  return string
