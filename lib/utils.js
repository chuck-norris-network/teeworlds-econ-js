module.exports.parseWeapon = function(id) {
  if (id === -1) {
    return 'suicide';
  }
  return ['hammer', 'gun', 'shotgun', 'rocket', 'laser', 'katana'][id];
};

module.exports.escape = function(input) {
  var string;
  string = input.replace(/"/g, '\\"');
  string = string.replace(/\n/g, '\\n');
  return string;
};
