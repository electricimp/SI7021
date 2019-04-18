# Si702x Temperature/Humidity Sensor #

This library provides a driver class for the [Si702x temperature/humidity sensor](http://www.silabs.com/Support%20Documents/TechnicalDocs/Si7021-A20.pdf). This class is compatible with the Si7020 and Si7021 &mdash; they differ only in measurement accuracy.

**To add this library to your project, add** `#require "Si702x.device.lib.nut:2.0.1"` **to the top of your device code**

## Hardware ##

The Si702x should be connected as follows:

![Si7020 Circuit](./circuit.png)

## Class Usage ##

### Constructor: Si702x(*impI2Cbus[, baseAddress]*) ###

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *impI2Cbus* | **i2c** object | Yes | The *configured* I&sup2;C bus to which the sensor is connected |
| *baseAddress* | Integer  | No | The sensor’s I&sup2;C address. Default: `0x80` |

#### Example ####

```squirrel
#require "Si702x.device.lib.nut:2.0.0"

// Configure the I2C bus on the imp001
hardware.i2c89.configure(CLOCK_SPEED_400_KHZ);

// Instantiate the sensor driver
tempHumid <- Si702x(hardware.i2c89);
```

## Class Methods ##

### read(*[callback]*) ###

This method takes a sensor reading. It can operate synchronously or asynchronously.

For synchronous operation, pass `null` or provide no argument.

For asynchronous operation, pass in a callback function. The callback should have one parameter of its own, *results*, which will receive the table *(see Return Value, below)* that is returned by the method in synchronous mode.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | No | An optional callback function which will receive the reading. Default: `null` |

#### Return Value ####

Table (the sensor reading results with the keys listed below) or nothing if the method is configured to run asynchronously.

| Results Table Key | Type | Slot Always Present | Description |
| --- | --- | --- | --- |
| *err* | String | No | If there, an error message |
| *temperature* | Float | Yes | Temperature (Celsius), or `null` if an error occured |
| *humidity* | Float | Yes | Relative humidity (%), or `null` if an error occured while reading humidity |

**Note** The *err* key will *only* be present if an error occurred. You should check for the existence of *err* before using the results.

#### Example ####

```squirrel
function printResult(result) {
  if ("err" in result) {
    server.log(result.err);
  } else {
    server.log(format("Temperature: %.01f°C, Relative Humidity: %.01f%%", result.temperature, result.humidity));
  }
}

// Take a reading and print the result
tempHumid.read(printResult);
```

## License ##

This library is licensed under the [MIT License](./LICENSE).
