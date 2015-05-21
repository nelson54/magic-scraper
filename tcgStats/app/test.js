var influx = require('influx');

var client = influx({
    // or single-host configuration
    host : 'sandbox.influxdb.com',
    username : 'admin',
    password : 'admin',
    database: 'mehsomething'
});



var point = {
 "name": "Wren's Run Vanquisher",
 "set":  "Lorwyn",
 "max":  3.57,
 "mid":  2.71,
 "min":  2.2
};



client.writePoint('whatever', point, [], function(e){
    console.log('Done.' + e);
    process.exit(1);
});



