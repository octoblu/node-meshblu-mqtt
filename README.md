Meshblu MQTT
===

An simple MQTT based client for connecting to [meshblu.octoblu.com](http://meshblu.octoblu.com)

Installation:
---
```
npm install meshblu-mqtt
```

Example:
---

```javascript
var Meshblu = require('meshblu-mqtt');
var config  = require('./meshblu.json');

// Config Example
// {
//   "uuid": "5632dd4a-e66b-43c7-bbbd-b264903e20bd",
//   "token": "c84bdb43febc2702110fc7d6a9aa91cc6b783ec1",
//   "hostname": "meshblu.octoblu.com",
//   "port": "1883"
// }

var meshblu = new Meshblu(config);
console.log('starting...');

meshblu.connect(function(response){
  console.log('ready', response);
  // Update Device - response emits event 'config'
  meshblu.update({uuid: config.uuid, skynet: 'rules'});

  // Send Data - response emits event 'data'
  meshblu.data({sensorData: 1500});

  // Message - response emits event 'message'
  var message = {
    devices: ['5682bd69-0199-46eb-b79b-0f585e5994e5'],
    topic: 'hello',
    payload: {ilove: 'food'}
  };
  meshblu.message(message);

  // Reset token - response emits event 'token'
  meshblu.resetToken({uuid: 'some-uuid'});

  // Generate New Session Token - response emits event 'generateAndStoreToken'
  meshblu.generateAndStoreToken({uuid: 'some-uuid'});

  // Get Public Key - response emits event 'getPublicKey'
  meshblu.getPublicKey({uuid: 'some-uuid'});

  // Whoami - - response emits event 'whoami'
  meshblu.whoami();
});
```

LICENSE
-------

(MIT License)

Copyright (c) 2014 Octoblu <info@octoblu.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
