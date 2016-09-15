# Parse status command output
#
# @private
# @param {String} output
# @return {Object}
parseStatus = (output) ->
  output.split('\n').map (line) ->
    matches = /^\[Server\]: id=([0-9]+) addr=(.+?):([0-9]+) name='(.+?)' score=([0-9-]+) ?(\(Admin\))?$/.exec line
    {
      cid: parseInt(matches[1])
      client: "#{matches[2]}:#{matches[3]}"
      player: matches[4]
      score: parseInt(matches[5])
      admin: !!matches[6]
    }

module.exports = parseStatus
