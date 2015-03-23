// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class Si702x {
    // Commands
    static RESET            = "\xFE";
    static MEASURE_RH       = "\xF5";
    static MEASURE_TEMP     = "\xF3";
    static READ_PREV_TEMP   = "\xE0";
    // Additional constants
    static RH_MULT      = 125.0/65536.0;
    static RH_ADD       = -6;
    static TEMP_MULT    = 175.72/65536.0;
    static TEMP_ADD     = -46.85;
    static TIMEOUT      = 200; // ms

    _i2c  = null;
    _addr  = null;

    // Constructor
    // Parameters:
    //      _i2c:     hardware i2c bus, must pre-configured
    //      _addr:    device address (optional)
    // Returns: (None)
    constructor(i2c, addr = 0x80)
    {
        _i2c  = i2c;
        _addr = addr;
    }

    // Resets the sensor to default settings
    function init() {
        _i2c.write(_addr, "", RESET);
    }

    // Polls the sensor for the result of a previously-initiated measurement
    // (gives up after TIMEOUT milliseconds)
    function _waitForResult(startTime, callback) {
        local result = _i2c.read(_addr, "", 2);
        if (result) {
            callback(result);
        } else if (hardware.millis() - startTime < TIMEOUT) {
            imp.wakeup(0, function() {
                _waitForResult(startTime, callback);
            }.bindenv(this));
        } else {
            throw "Si702x timed out waiting for result";
        }
    }

    // Starts a relative humidity measurement
    function _readRH(callback) {
        _i2c.write(_addr, MEASURE_RH);
        _waitForResult(hardware.millis(), callback);
    }

    // Reads and returns the temperature value from the previous humidity measurement
    function _readTempFromPrev() {
        local rawTemp = _i2c.read(_addr, READ_PREV_TEMP, 2);
        if (rawTemp) {
            return TEMP_MULT*((rawTemp[0] << 8) + rawTemp[1]) + TEMP_ADD;
        }
    }

    // Initiates a relative humidity measurement,
    // then passes the humidity and temperature readings to the user-supplied callback
    function read(callback) {
        // Measure and read the humidity first
        _readRH(function(rawHumidity) {
            local humidity = RH_MULT*((rawHumidity[0] << 8) + rawHumidity[1]) + RH_ADD;
            // Then read the temperature reading from the humidity measurement
            local temp = _readTempFromPrev();
            // And pass it all to the user's callback
            callback({"temperature": temp, "humidity": humidity});
        }.bindenv(this));
    }
}