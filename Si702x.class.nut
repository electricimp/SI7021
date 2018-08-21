// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class Si702x {
    static VERSION          = "1.0.1";
    // Commands
    static RESET            = "\xFE";
    static MEASURE_RH       = "\xF5";
    static MEASURE_TEMP     = "\xF3";
    static READ_PREV_TEMP   = "\xE0";
    // Additional constants
    static RH_MULT      = 125.0/65536.0;    // ------------------------------------------------
    static RH_ADD       = -6;               // These values are used in the conversion equation
    static TEMP_MULT    = 175.72/65536.0;   // from the Si702x datasheet
    static TEMP_ADD     = -46.85;           // ------------------------------------------------
    static TIMEOUT_MS   = 100;

    _i2c  = null;
    _addr = null;

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
        _i2c.write(_addr, RESET);
    }

    // Polls the sensor for the result of a previously-initiated measurement
    // (gives up after TIMEOUT milliseconds)
    function _pollForResult(startTime, callback) {
        local result = _i2c.read(_addr, "", 2);
        if (result) {
            callback(result);
        } else if (hardware.millis() - startTime < TIMEOUT_MS) {
            imp.wakeup(0, function() {
                _pollForResult(startTime, callback);
            }.bindenv(this));
        } else {
            // Timeout
            callback(null);
        }
    }

    // Starts a relative humidity measurement
    function _readRH(callback=null) {
        _i2c.write(_addr, MEASURE_RH);
        local startTime = hardware.millis();
        if (callback == null) {
            local result = _i2c.read(_addr, "", 2);
            while (result == null && hardware.millis() - startTime < TIMEOUT_MS) {
                result = _i2c.read(_addr, "", 2);
            }
            return result;
        } else {
            _pollForResult(startTime, callback);
        }
    }

    // Reads and returns the temperature value from the previous humidity measurement
    function _readTempFromPrev() {
        local rawTemp = _i2c.read(_addr, READ_PREV_TEMP, 2);
        if (rawTemp) {
            return TEMP_MULT*((rawTemp[0] << 8) + rawTemp[1]) + TEMP_ADD;
        } else {
            server.log("Si702x i2c read error: " + _i2c.readerror());
            return null;
        }
    }

    // Initiates a relative humidity measurement,
    // then passes the humidity and temperature readings as a table to the user-supplied callback, if it exists
    // or returns them to the caller, if it doesn't
    function read(callback=null) {
        if (callback == null) {
            local rawHumidity = _readRH();
            local temp = _readTempFromPrev();
            if (rawHumidity == null || temp == null) {
                return {"err": "error reading temperature", "temperature": null, "humidity": null};
            }
            local humidity = RH_MULT*((rawHumidity[0] << 8) + rawHumidity[1]) + RH_ADD;
            return {"temperature": temp, "humidity": humidity};
        } else {
            // Measure and read the humidity first
            _readRH(function(rawHumidity) {
                // If it failed, return an error
                if (rawHumidity == null) {
                    callback({"err": "reading timed out", "temperature": null, "humidity": null});
                    return;
                }
                // Convert raw humidity value to relative humidity in percent, clamping the value to 0-100%
                local humidity = RH_MULT*((rawHumidity[0] << 8) + rawHumidity[1]) + RH_ADD;
                if (humidity < 0) { humidity = 0.0; }
                else if (humidity > 100) { humidity = 100.0; }
                // Read the temperature reading from the humidity measurement
                local temp = _readTempFromPrev();
                if (temp == null) {
                    callback({"err": "error reading temperature", "temperature": null, "humidity": null});
                    return;
                }
                // And pass it all to the user's callback
                callback({"temperature": temp, "humidity": humidity});
            }.bindenv(this));
        }
    }
}
