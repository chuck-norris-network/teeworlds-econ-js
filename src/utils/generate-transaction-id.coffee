crypto = require 'crypto'

# Generate random string
#
# @return {String}
module.exports = () ->
  crypto.randomBytes(16).toString('hex')
