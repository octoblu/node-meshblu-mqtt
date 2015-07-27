_               = require 'lodash'
url             = require 'url'
{EventEmitter2} = require 'eventemitter2'
debug           = require('debug')('meshblu-mqtt')

PROXY_EVENTS = ['close', 'error', 'reconnect', 'offline', 'pong', 'open', 'config', 'data', 'generateAndStoreToken', 'token', 'publicKey']

class Meshblu extends EventEmitter2
  constructor: (options={}, dependencies={})->
    super wildcard: true
    @mqtt = dependencies.mqtt ? require 'mqtt'
    defaults =
      keepalive: 10
      protocolId: 'MQIsdp'
      protocolVersion: 4
      qos: 0
      clientId: options.uuid
      username: options.uuid
      password: options.token
      reconnectPeriod: 5000
    @options = _.defaults options, defaults

  connect: (callback=->) =>
    uri = @_buildUri()
    options = _.omit @options, ['port', 'host', 'hostname', 'protocol']
    debug 'connecting...', uri
    @client = @mqtt.connect uri, options
    @client.once 'connect', =>
      response = _.pick @options, 'uuid', 'token'
      debug 'connected to mqtt meshblu', response
      @client.subscribe @options.uuid, qos: @options.qos
      callback response

    @client.on 'message', @_messageHandler

    _.each PROXY_EVENTS, (event) => @_proxy event

  publish: (topic, data) =>
    throw new Error 'No Active Connection' unless @client?
    debug 'publish', topic, data
    @client.publish topic, JSON.stringify(data)

  # API Functions
  message: (params) =>
    @publish 'message', params

  data: (data) =>
    @publish 'data', data

  subscribe: (params) =>
    @client.subscribe params

  unsubscribe: (params) =>
    @client.unsubscribe params

  update: (data) =>
    @publish 'update', data

  resetToken: (data) =>
    @publish 'resetToken', data

  getPublicKey: (data) =>
    @publish 'getPublicKey', data

  generateAndStoreToken: (data) =>
    @publish 'generateAndStoreToken', data

  whoami: =>
    @publish 'whoami'

  # Private Functions
  _buildUri: =>
    options = _.pick _.clone(@options), ['protocol', 'hostname', 'port']
    defaults =
      protocol: 'mqtt'
      hostname: 'meshblu.octoblu.com'
      port: 1883
    uriOptions = _.defaults options, defaults
    url.format uriOptions

  _messageHandler: (uuid, message) =>
    message = message.toString()
    debug '_messageHandler', message
    try
      message = JSON.parse message
    catch error
      debug 'unable to parse message', message
    return @emit 'message', message

  _proxy: (event) =>
    @client.on event, =>
      debug 'proxy ' + event, _.first arguments
      @emit event, arguments...

  _uuidOrObject: (data) =>
    return uuid: data if _.isString data
    return data

module.exports = Meshblu
