'use strict';

var mqtt = require("mqtt");
var util = require('util');
var EventEmitter = require('events').EventEmitter;

var DEFAULT_TIMEOUT = 10000;

function Connection(opt){

  EventEmitter.call(this);

  var self = this;

  this._callbackHandlers = {};
  this._ackId = 0;

  if(!opt || typeof opt !== 'object'){
    throw new Error('invalid options');
  }

  this.options = opt;
  this.options.protocol = 'mqtt';


  this.mqttsettings = {
    keepalive: 1000,
    protocolId: 'MQIsdp',
    protocolVersion: 3,
    clientId: this.options.uuid,
    username: this.options.uuid,
    password: this.options.token,
    reconnectPeriod: this.options.reconnectPeriod || 5000
  };

  if (this.options.qos == undefined){
    this.options.qos = 0;
  }

  try {
    this.mqttclient = mqtt.createClient(this.options.port || this.options.mqttport || 1883,
                                        this.options.host || this.options.mqtthost || 'mqtt.skynet.im',
                                        this.mqttsettings);

    this.mqttclient.on('connect', function(a, b){
      console.log('...connected via mqtt',a,b);
      self.mqttclient.subscribe(self.options.uuid, {qos: self.options.qos});
      self.emit('ready');
    });

    this.mqttclient.on('close', function(){
      console.log('...closed via mqtt');
    });


    this.mqttclient.on('error', function(error){
      console.log('error connecting via mqtt');
      self.emit('error', error);
    });


    this.mqttclient.on('message', function(topic, data){
      try{
        if(typeof data === 'string'){
          data = JSON.parse(data);
        }

        if(data.topic === 'messageAck'){
          var msg = data.data;
          if(self._callbackHandlers[msg.ack]){
            try{
              self._callbackHandlers[msg.ack](msg.payload);
              delete self._callbackHandlers[msg.ack];
            }
            catch(err){
              console.log('error resolving callback', err);
            }
          }
        }
        else{
          self._handleAckRequest(data.topic, data.data);
        }

      }catch(exp){
        console.log('error on message', exp);
        //self.emit('error', 'error receiving message: ' + exp);
      }
    });

  } catch(err) {
    console.log(err);
  }

}

util.inherits(Connection, EventEmitter);


//Provide callback when message with ack requests comes in from another client
Connection.prototype._handleAckRequest = function(topic, data){
  var self = this;
  //console.log('incoming', topic, data);
  if(data){
    if(data.ack && data.fromUuid && topic !== 'messageAck'){
      //TODO clean these up if not used
      self.emit(topic, data, function(response){
        var responseData = {
          devices: data.fromUuid,
          ack: data.ack,
          payload: response
        };
        self.mqttclient.publish('messageAck', JSON.stringify(responseData), {qos: self.options.qos});
      });
    }else{
      self.emit(topic, data);
    }
  }
};

//Allow for making RPC requests to other clients
Connection.prototype._emitWithAck = function(topic, data, fn){
  var self = this;
  if(data){
   if(fn){
      var ack = ++this._ackId;
      data.ack = ack;
      self._callbackHandlers[ack] = fn;
      var timeout = data.timeout || DEFAULT_TIMEOUT;
      //remove handlers
      setTimeout(function(){
        if(self._callbackHandlers[ack]){
          self._callbackHandlers[ack]({error: 'timeout ' + timeout});
          delete self._callbackHandlers[ack];
        }
      }, timeout);
    }
    this.mqttclient.publish(topic, JSON.stringify(data), {qos: this.options.qos});
  }
  return self;
};

Connection.prototype.message = function(data, fn) {
  return this._emitWithAck('message', data, fn);
};

Connection.prototype.config = function(data, fn) {
  return this._emitWithAck('gatewayConfig', data, fn);
};

Connection.prototype.gatewayConfig = function(data, fn) {
  return this._emitWithAck('gatewayConfig', data, fn);
};


Connection.prototype.update = function(data, fn) {
  return this._emitWithAck('update', data, fn);
};

Connection.prototype.whoami = function(data, fn) {
  return this._emitWithAck('whoami', {}, fn);
};


Connection.prototype.subscribe = function(uuid, fn) {
  this.mqttclient.subscribe(uuid + '_bc', {qos: this.options.qos});
  return this;
};

Connection.prototype.unsubscribe = function(data, fn) {
  this.mqttclient.unsubscribe(data.uuid + '_bc');
  return this;
};


Connection.prototype.data = function(data) {
  if(data){
    data.uuid = this.options.uuid;
  }
  this.mqttclient.publish('data', JSON.stringify(data), {qos: this.options.qos});
  return this;
};

module.exports = Connection;
