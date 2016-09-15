# Format client ip:port string
#
# @private
# @param {Object} client
# @return {String}
formatClient = (client) ->
  return null unless client
  return null unless client.ip or client.port

  return client.ip + ':' + client.port

module.exports = formatClient
