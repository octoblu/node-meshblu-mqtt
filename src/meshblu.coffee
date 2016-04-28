_               = require 'lodash'
url             = require 'url'
uuid            = require 'uuid'
{EventEmitter2} = require 'eventemitter2'
debug           = require('debug')('meshblu-mqtt')

PROXY_EVENTS = ['close', 'error', 'reconnect', 'offline', 'pong', 'open']

class Meshblu extends EventEmitter2
  constructor: (options={}, dependencies={})->
    super wildcard: true
    options = _.cloneDeep options
    {@uuid, @token} = options
    @clientId = uuid.v4()
    @replyTopic = "#{@uuid or 'guest'}/#{@clientId}"
    @mqtt = dependencies.mqtt ? require 'mqtt'
    defaults =
      keepalive: 10
      protocolId: 'MQIsdp'
      protocolVersion: 3
      qos: 0
      username: @uuid
      password: @token
      reconnectPeriod: 5000
      clientId: @clientId
    @options = _.defaults options, defaults
    @messageCallbacks = {}
    debug {@options}

  connect: (callback=->) =>
    uri = @_buildUri()

    @client = @mqtt.connect uri, @options
    @client.once 'connect', =>
      response = _.pick @options, 'uuid', 'token'
      topics = [@replyTopic]
      debug topics
      @mqttSubscribe topics, qos: @options.qos
      @mqttPublish 'meshblu.firehose.request', {@replyTopic} if @uuid?
      callback response

    @client.on 'message', @_messageHandler

    _.each PROXY_EVENTS, (event) => @_proxy event

  mqttPublish: (topic, data) =>
    @client.publish topic, JSON.stringify(data)

  mqttSubscribe: (topics, options) =>
    @client.subscribe topics, options

  # API Functions
  message: (data, callback) =>
    @_makeJob 'SendMessage', null, data, callback

  createSessionToken: (uuid, data, callback) =>
    @_makeJob 'CreateSessionToken', toUuid: uuid, data, callback

  register: (data, callback) =>
    @_makeJob 'RegisterDevice', null, data, callback

  unregister: (uuid, callback) =>
    @_makeJob 'UnregisterDevice', toUuid: uuid, null, callback

  searchDevices: (uuid, data={}, callback) =>
    @_makeJob 'SearchDevices', fromUuid: uuid, data, callback

  status: (callback) =>
    @_makeJob 'GetStatus', null, null, callback

  subscribe: (uuid, data, callback) =>
    @_makeJob 'CreateSubscription', toUuid: uuid, data, callback

  unsubscribe: (uuid, data, callback) =>
    @_makeJob 'DeleteSubscription', toUuid: uuid, data, callback

  update: (uuid, data, callback) =>
    @_makeJob 'UpdateDevice', toUuid: uuid, data, callback

  whoami: (callback) =>
    @_makeJob 'GetDevice', toUuid: @uuid, null, callback

  _makeJob: (jobType, metadata, data, callback) =>
    metadata = _.clone metadata || {}
    metadata.jobType = jobType
    callbackId = uuid.v4()
    @messageCallbacks[callbackId] = callback;

    if data?
      rawData = JSON.stringify data
    request = {job: {metadata, rawData}, callbackId, @replyTopic}

    throw new Error 'No Active Connection' unless @client?
    @mqttPublish 'meshblu.request', request

  # Private Functions
  _buildUri: =>
    defaults =
      protocol: 'mqtt'
      hostname: 'meshblu.octoblu.com'
      port: 1883
    uriOptions = _.defaults {}, @options, defaults
    url.format uriOptions

  _messageHandler: (topic, message) =>
    message = message.toString()
    try
      message = JSON.parse message
    catch error
      debug 'unable to parse message', message

    debug '_messageHandler:', topic, message
    return unless _.isObject message
    return if @_handleCallbackResponse message
    return @emit message.type, message.data if message.type?

  _handleCallbackResponse: (message) =>
    id = message?.callbackId
    return false unless id?
    callback = @messageCallbacks[id] ? ->
    try
      response = JSON.parse message.data
    catch error
      response = null

    callback new Error(message.data) if message.type == 'meshblu.error'
    callback null, response if message.type != 'meshblu.error'
    delete @messageCallbacks[id]
    return true

  _proxy: (event) =>
    @client.on event, =>
      debug 'proxy ' + event, _.first arguments
      @emit event, arguments...

module.exports = Meshblu
