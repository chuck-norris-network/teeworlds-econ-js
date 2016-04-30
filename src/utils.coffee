module.exports.parseWeapon = (id) ->
  return 'suicide' if id == '-1'
  return ['hammer', 'gun', 'shotgun', 'rocket', 'laser', 'katana'][id]
