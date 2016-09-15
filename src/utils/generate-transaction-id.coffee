crypto = require 'crypto'

# Generate random string
#
# @private
# @return {String}
generateTransactionId = () ->
  crypto.randomBytes(16).toString('hex')

module.exports = generateTransactionId
