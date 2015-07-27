{EventEmitter} = require 'events'
Meshblu        = require '../src/meshblu'

describe 'Meshblu', ->
  beforeEach ->
    @mqtt = {}
    @mqtt.connect = sinon.stub().returns @mqtt
    @mqtt.on = sinon.stub()
    @mqtt.publish = sinon.stub()
    @mqtt.subscribe = sinon.stub()

  describe '->connect', ->
    describe 'when instantiated with node url params', ->
      beforeEach ->
        config =
          hostname: 'localhost'
          port: 1234
          uuid: 'some-uuid'
          token: 'some-token'
        @callback = sinon.spy()

        @sut = new Meshblu config, mqtt: @mqtt
        @sut.connect @callback

      it 'should have been called with a formated url', ->
        expect(@mqtt.connect).to.have.been.calledWith 'mqtt:localhost:1234',
          keepalive: 10
          protocolId: 'MQIsdp'
          protocolVersion: 4
          qos: 0
          clientId: 'some-uuid'
          username: 'some-uuid'
          password: 'some-token'
          token:    'some-token'
          uuid:     'some-uuid'
          reconnectPeriod: 5000
