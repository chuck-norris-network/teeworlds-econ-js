split = require 'split'
splitText = require 'split-text'
debug = require 'debug'

module.exports = {}
module.exports.debug = {}

# Split a Text Stream into a Line Stream
module.exports.split = split

# Split a text into an array of chunks
module.exports.splitText = splitText

# Debug connection
module.exports.debug.connection = debug 'econ:connection'

# Debug Teeworlds events
module.exports.debug.events = debug 'econ:events'

# Parse ID of weapon item to human readable string
#
# @param {String} id
# @return {String}
module.exports.parseWeapon = (id) ->
  return 'suicide' if id == -1
  return ['hammer', 'gun', 'shotgun', 'rocket', 'laser', 'katana'][id]

# Escape econ command
#
# @param {String} input
# @return {String}
module.exports.escape = (input) ->
  # escape backslashes
  string = input.replace /\\/g, '\\\\'

  # escape quotes
  string = string.replace /"/g, '\\"'

  # escape line breaks
  string = string.replace /\n/g, '\\n'

  return string
