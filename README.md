# Driver for the Si702x Temperature/Humidity Sensor

Author: [Juan Albanell](https://github.com/juanderful11/)

Driver class for a [Si702x temperature/humidity sensor](http://www.silabs.com/Support%20Documents/TechnicalDocs/Si7021-A20.pdf). This class is compatible with the Si7020 and Si7021 &ndash; they differ only in measurement accuracy.

## Hardware

The Si702x should be connected as follows:

![Si7020 Circuit](./circuit.png)

## Class Usage

### Constructor

To instantiate a new Si702x object you need to pass in a preconfigured I&sup2;C object and an optional I&sup2;C base address. If no base address is supplied, the default address of `0x80` will be used.

```squirrel
hardware.i2c12.configure(CLOCK_SPEED_100_KHZ)
tempHumid <- Si702x(hardware.i2c12)
```

### Class Methods

### readTemp()

The **readTemp()** method returns the temperature in degrees Celsius:

```squirrel
server.log(tempHumid.readTemp() + "C")
```

### readHumidity()

The **readHumidity()** function returns the relative humidity (0-100 per cent):

```squirrel
server.log(tempHumid.readHumidity() + "%")
```

# License

The Si702x library is licensed under the [MIT License](./LICENSE).
