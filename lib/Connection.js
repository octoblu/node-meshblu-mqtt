'use strict';

var mqtt = require("mqtt");
var util = require('util');
var EventEmitter = require('events').EventEmitter;



function Connection(opt){

  EventEmitter.call(this);

  var self = this;

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

    //console.log(this.mqttclient.options);

    //this.mqttclient.subscribe(this.options.uuid, {qos: this.options.qos});


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
        //console.log('data', data);
        self.emit(data.topic, data.data);
      }catch(exp){
        self.emit('error', 'error receiving message: ' + exp);
      }
      //console.log('on message', topic, typeof data, data);
    });

  } catch(err) {
    console.log(err);
  }

}

util.inherits(Connection, EventEmitter);


Connection.prototype.skynetPublish = function(skynetTopic, data){
  if(data){
    this.mqttclient.publish(skynetTopic, JSON.stringify(data), {qos: this.options.qos});
  }
  return this;
};

Connection.prototype.message = function(data) {

  // Send the API request to Skynet
  if (typeof data === 'object'){
    this.skynetPublish('message', data);
    return this;
  }

};


Connection.prototype.update = function(data) {
  this.skynetPublish('update', data);
  return this;
};


Connection.prototype.whoami = function(data) {
  this.skynetPublish('whoami', data);
  return this;
};

Connection.prototype.devices = function(data, fn) {
  this.skynetPublish('devices', data);
  return this;
};


Connection.prototype.status = function(data) {
  this.skynetPublish('status', data);
  return this;
};

Connection.prototype.subscribe = function(uuid, fn) {
  this.mqttclient.subscribe(uuid + '_bc', {qos: this.options.qos});
  return this;
};

Connection.prototype.unsubscribe = function(data, fn) {
  this.mqttclient.unsubscribe(data.uuid + '_bc');
  return this;
};

Connection.prototype.events = function(data, fn) {
  this.skynetPublish('events', data);
  return this;
};

Connection.prototype.data = function(data) {
  if(data){
    data.uuid = this.options.uuid;
  }
  this.skynetPublish('data', data);
  return this;
};

module.exports = Connection;
