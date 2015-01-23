```
 SSSSS  kk                            tt
SS      kk  kk yy   yy nn nnn    eee  tt
 SSSSS  kkkkk  yy   yy nnn  nn ee   e tttt
     SS kk kk   yyyyyy nn   nn eeeee  tt
 SSSSS  kk  kk      yy nn   nn  eeeee  tttt
                yyyyy
```

meshblu-mqtt
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
var meshblu = require('meshblu-mqtt');

var conn = meshblu.createConnection({
  "uuid": "xxxxxxxxxxxx-My-UUID-xxxxxxxxxxxxxx",
  "token": "xxxxxxx-My-Token-xxxxxxxxx",
  "qos": 0, // MQTT Quality of Service (0=no confirmation, 1=confirmation, 2=N/A)
  "host": "localhost", // optional - defaults to meshblu.im
  "port": 1883  // optional - defaults to 1883
});

conn.on('ready', function(){

  console.log('UUID AUTHENTICATED!');

  //Listen for messages
  conn.on('message', function(message){
    console.log('message received', message);
  });


  // Send a message to another device
  conn.message({
    "devices": "xxxxxxx-some-other-uuid-xxxxxxxxx",
    "payload": {
      "meshblu":"online"
    }
  });


  // Broadcast a message to any subscribers to your uuid
  conn.message({
    "devices": "*",
    "payload": {
      "hello":"meshblu"
    }
  });


  // Subscribe to broadcasts from another device
  conn.subscribe('xxxxxxx-some-other-uuid-xxxxxxxxx');


  // Log sensor data to meshblu
  conn.data({temperature: 75, windspeed: 10});

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
