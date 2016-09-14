# Parse ID of weapon item to human readable string
#
# @param {String} id
# @return {String}
module.exports = (id) ->
  return 'suicide' if id == -1
  return ['hammer', 'gun', 'shotgun', 'rocket', 'laser', 'katana'][id]
