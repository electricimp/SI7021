Driver for the Si702x Temperature/Humidity Sensor
=================================================

Author: [Gino](https://github.com/imp-gino/)

Driver class for a [Si702x temperature/humidity sensor](http://www.silabs.com/Support%20Documents/TechnicalDocs/Si7021-A20.pdf). This class is compatible with the Si7020 and Si7021 &ndash; they differ only in measurement accuracy.

**To add this library to your project, add** `#require "Si702x.class.nut:1.0.0"` **to the top of your device code**

## Hardware

The Si702x should be connected as follows:

![Si7020 Circuit](./circuit.png)

## Class Usage

### Constructor

To instantiate a new Si702x object you need to pass in a preconfigured I&sup2;C object and an optional I&sup2;C base address. If no base address is supplied, the default address of `0x80` will be used.

```squirrel
#require "Si702x.class.nut:1.0.0"

hardware.i2c89.configure(CLOCK_SPEED_400_KHZ)
tempHumid <- Si702x(hardware.i2c89)
```

### Class Methods

#### read([callback])

The **read()** method takes an optional callback for asynchronous operation. The callback should take one parameter: a results table (see below). If the callback is null or omitted, the method will return the results table to the caller instead:

| Key         | Type   | Description              |
| ----------- | ------ | ------------------------ |
| err         | string | The error (if it exists) |
| temperature | float  | Temperature (°C)         |
| humidity    | float  | Relative humidity (%)    |

**NOTE:** The ```err``` key will *only* be present if an error occured. You should check for the existence of ```err``` before using the results.

### Example Usage
```squirrel
tempHumid.read(function(result) {
    if ("err" in result) {
        server.log(result.err);
        return;
    }
    server.log(format("Temperature: %.01f°C, Relative Humidity: %.01f%%", result.temperature, result.humidity));
});
```

## License

The Si702x library is licensed under the [MIT License](./LICENSE).
