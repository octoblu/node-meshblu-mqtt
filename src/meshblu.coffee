_               = require 'lodash'
url             = require 'url'
uuid            = require 'uuid'
{EventEmitter2} = require 'eventemitter2'
debug           = require('debug')('meshblu-mqtt')

PROXY_EVENTS = ['close', 'error', 'reconnect', 'offline', 'pong', 'open']

class Meshblu extends EventEmitter2
  constructor: (options={}, dependencies={})->
    super wildcard: true
    clientId = uuid.v4()
    options = _.cloneDeep options
    {@uuid, @token} = options
    @replyTopic = "#{@uuid or 'guest'}/#{clientId}"
    @mqtt = dependencies.mqtt ? require 'mqtt'
    defaults =
      keepalive: 10
      protocolId: 'MQIsdp'
      protocolVersion: 3
      qos: 0
      username: @uuid
      password: @token
      reconnectPeriod: 5000
      clientId: clientId
      hostname: "meshblu.octoblu.com"
      port: '8883'

    @options = _.defaults options, defaults
    @messageCallbacks = {}
    debug {@options}

  connect: (callback=->) =>
    {protocol, hostname, port} = @options
    uri = @_buildUri(protocol, hostname, port)
    debug 'connecting to uri', uri
    @client = @mqtt.connect uri, @options
    @client.once 'connect', =>
      response = _.pick @options, 'uuid', 'token'
      topics = [@replyTopic]
      @mqttSubscribe topics, qos: @options.qos
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

  requestFirehose: (auth, callback) =>
    callbackId = @_registerCallback callback
    auth ?= {@uuid, @token}
    @mqttPublish 'meshblu.firehose.request', {auth, @replyTopic, callbackId} if @uuid?

  # Private Functions
  _registerCallback: (callback) =>
    callbackId = uuid.v4()
    @messageCallbacks[callbackId] = callback;
    return callbackId

  _makeJob: (jobType, metadata, data, callback) =>
    metadata = _.clone metadata || {}
    metadata.jobType = jobType
    callbackId = @_registerCallback callback

    if data?
      rawData = JSON.stringify data
    request = {job: {metadata, rawData}, callbackId, @replyTopic}

    throw new Error 'No Active Connection' unless @client?
    @mqttPublish 'meshblu.request', request

  _buildUri: ( protocol, hostname, port ) =>
    protocol ?= 'wss'   if port-0 == 3001
    protocol ?= 'ws'    if port-0 == 3000
    protocol ?= 'mqtts' if port-0 == 8883
    protocol ?= 'mqtt'
    url.format { protocol, hostname, port }

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
