# Format client ip:port string
#
# @param {Object} client
# @return {String}
module.exports = (client) ->
  return null unless client
  return null unless client.ip or client.port

  return client.ip + ':' + client.port
