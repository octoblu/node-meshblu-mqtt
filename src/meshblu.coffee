_               = require 'lodash'
url             = require 'url'
uuid            = require 'uuid'
{EventEmitter2} = require 'eventemitter2'
debug           = require('debug')('meshblu-mqtt')

PROXY_EVENTS = ['close', 'error', 'reconnect', 'offline', 'pong', 'open', 'config', 'data']

class Meshblu extends EventEmitter2
  constructor: (options={}, dependencies={})->
    super wildcard: true
    options = _.cloneDeep options
    {@uuid, @token} = options
    @queueName = "#{@uuid or 'guest'}.#{uuid.v4()}"
    @firehoseQueueName = "#{@uuid}.firehose"
    debug {@queueName}
    @mqtt = dependencies.mqtt ? require 'mqtt'
    defaults =
      keepalive: 10
      protocolId: 'MQIsdp'
      protocolVersion: 3
      qos: 0
      username: @uuid
      password: @token
      reconnectPeriod: 5000
      clientId: @queueName
    @options = _.defaults options, defaults
    @messageCallbacks = {}
    debug {@options}

  connect: (callback=->) =>
    uri = @_buildUri()

    @client = @mqtt.connect uri, @options
    @client.once 'connect', =>
      response = _.pick @options, 'uuid', 'token'
      # @client.subscribe "#{@@uuid}.*"
      subscriptions = [@queueName] #, @firehoseQueueName]
      # debug subscriptions
      @client.subscribe subscriptions, qos: @options.qos
      # @client.publish 'meshblu.firehose.request', JSON.stringify({@uuid})
      # @client.publish 'meshblu.cache-auth', JSON.stringify(auth: {@uuid, @token})
      # @client.publish 'meshblu.reply-to', JSON.stringify(replyTo: @queueName)
      callback response

    @client.on 'message', @_messageHandler

    _.each PROXY_EVENTS, (event) => @_proxy event

  subscribeTopic: (params) =>
    @client.subscribe params

  unsubscribeTopic: (params) =>
    @client.unsubscribe params

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
    #metadata.auth = {@uuid, @token}
    metadata.jobType = jobType
    callbackInfo = id: uuid.v4()
      #replyTo: @queueName
    @messageCallbacks[callbackInfo.id] = callback;

    if data?
      rawData = JSON.stringify data
    message = {job: {metadata, rawData}, callbackInfo}

    throw new Error 'No Active Connection' unless @client?
    @client.publish 'meshblu.request', JSON.stringify(message)

  # Private Functions
  _buildUri: =>
    defaults =
      protocol: 'mqtt'
      hostname: 'meshblu.octoblu.com'
      port: 1883
    uriOptions = _.defaults {}, @options, defaults
    url.format uriOptions

  _messageHandler: (uuid, message) =>
    debug '_messageHandler!'
    message = message.toString()
    try
      message = JSON.parse message
    catch error
      debug 'unable to parse message', message

    return unless message?

    # debug '_messageHandler', message

    return if @_handleCallbackResponse message
    debug 'doing an emit topic!'
    return @emit message.topic, message.data if message.topic?

  _handleCallbackResponse: (message) =>
    # console.log {message}
    id = message?.callbackInfo?.id
    return false unless id?
    callback = @messageCallbacks[id] ? ->
    try
      response = JSON.parse message.data
    catch error
      response = null

    callback new Error(message.data) if message.topic == 'error'
    callback null, response if message.topic != 'error'
    delete @messageCallbacks[id]
    return true

  _proxy: (event) =>
    @client.on event, =>
      debug 'proxy ' + event, _.first arguments
      @emit event, arguments...

  _uuidOrObject: (data) =>
    return uuid: data if _.isString data
    return data

module.exports = Meshblu
