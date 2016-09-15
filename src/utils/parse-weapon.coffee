# Parse ID of weapon item to human readable string
#
# @private
# @param {String} id
# @return {String}
parseWeapon = (id) ->
  return 'suicide' if id == -1
  return ['hammer', 'gun', 'shotgun', 'rocket', 'laser', 'katana'][id]

module.exports = parseWeapon
