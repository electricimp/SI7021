// Copyright (c) 2014 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class Si702x {
    static READ_RH      = "\xF5";
    static READ_TEMP    = "\xF3";
    static PREV_TEMP    = "\xE0";
    static RH_MULT      = 125.0/65536.0;
    static RH_ADD       = -6;
    static TEMP_MULT    = 175.72/65536.0;
    static TEMP_ADD     = -46.85;
    static TIMEOUT      = 200; // ms

    _i2c  = null;
    _addr  = null;

    // class constructor
    // Input:
    //      _i2c:     hardware i2c bus, must pre-configured
    //      _addr:     slave address (optional)
    // Return: (None)
    constructor(i2c, addr = 0x80)
    {
        _i2c  = i2c;
        _addr = addr;
    }

    // Input: (none)
    // Return: relative humidity (float)
    function readRH() {
        _i2c.write(_addr, READ_RH);
        local reading = _i2c.read(_addr, "", 2);
        local start = hardware.millis();
        while (reading == null && (hardware.millis() - start < TIMEOUT)) {
            reading = _i2c.read(_addr, "", 2);
        }
        if (hardware.millis() - start >= TIMEOUT) {
            throw "Timed out waiting for relative humidity response from SI7021";
        }
        local humidity = RH_MULT*((reading[0] << 8) + reading[1]) + RH_ADD;
        return humidity;
    }

    // read the temperature
    // Input: (none)
    // Return: temperature in celsius (float)
    function readTemp() {
        _i2c.write(_addr, READ_TEMP);
        local reading = _i2c.read(_addr, "", 2);
        local start = hardware.millis();
        while (reading == null && (hardware.millis() - start < TIMEOUT)) {
            reading = _i2c.read(_addr, "", 2);
        }
        if (hardware.millis() - start >= TIMEOUT) {
            throw "Timed out waiting for temperature response from SI7021";
        }
        local temperature = TEMP_MULT*((reading[0] << 8) + reading[1]) + TEMP_ADD;
        return temperature;
    }

    // read the temperature from previous rh measurement
    // this method does not have to recalculate temperature so it is faster
    // Input: (none)
    // Return: temperature in celsius (float)
    function readPrevTemp() {
        _i2c.write(_addr, PREV_TEMP);
        local reading = _i2c.read(_addr, "", 2);
        if (!reading) { throw "I2C Error reading previous temperature from SI7021"; }
        local temperature = TEMP_MULT*((reading[0] << 8) + reading[1]) + TEMP_ADD;
        return temperature;
    }
}
