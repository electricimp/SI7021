// MIT License
//
// Copyright 2015-19 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

enum SI702X {
    // Commands
    RESET          = "\xFE",
    MEASURE_RH     = "\xF5",
    MEASURE_TEMP   = "\xF3",
    READ_PREV_TEMP = "\xE0",
    // Values used in conversion equation from Si702x datasheet
    RH_MULT        = 0.0019073486328125,                // 125.0/65536.0
    RH_ADD         = -6,
    TEMP_MULT      = 0.0026812744326889514923095703125,  // 175.72/65536.0
    TEMP_ADD       = -46.85,
    TIMEOUT_MS     = 100,
    // Error Messages
    ERROR_READ_TIMEOUT = "ERROR: Reading timed out",
    ERROR_TEMP_READ    = "ERROR: Reading temperature failed, i2c read error: %i"
}

class Si702x {

    static VERSION = "2.0.1";

    _i2c  = null;
    _addr = null;

    // Constructor
    // Parameters:
    //      _i2c:     hardware i2c bus, must pre-configured
    //      _addr:    device address (optional)
    // Returns: (None)
    constructor(i2c, addr = 0x80) {
        _i2c  = i2c;
        _addr = addr;
    }

    // Resets the sensor to default settings
    function init() {
        _i2c.write(_addr, SI702X.RESET);
    }

    // Initiates a relative humidity measurement,
    // then passes the humidity and temperature readings as a table to the user-supplied callback, if it exists
    // or returns them to the caller, if it doesn't
    function read(callback = null) {
        if (callback == null) {
            return _processResult(_readRH());
        } else {
            // Measure and read the humidity first
            _readRH(function(rawHumidity) {
                callback(_processResult(rawHumidity));
            }.bindenv(this));
        }
    }

    // Takes raw humidity result and returns a results table with relative humidity, temperature and possibly error
    function _processResult(rawHumidity) {
        // Result table will always have "temperature" and "hummidity" slots, and may contain the "err" slot
        local result = {
            "temperature" : null,
            "humidity"    : null
        };

        if (rawHumidity == null) {
            // If rawHumidity read failed, add an error to the table
            result.err <- SI702X.ERROR_READ_TIMEOUT;
        } else {
            // Convert raw humidity value to relative humidity in percent, clamping the value to 0-100%
            local humidity = SI702X.RH_MULT*((rawHumidity[0] << 8) + rawHumidity[1]) + SI702X.RH_ADD;
            if (humidity < 0) {
                humidity = 0.0;
            } else if (humidity > 100) {
                humidity = 100.0;
            }
            result.humidity = humidity;

            // Get the temperature reading from the humidity measurement
            local temp = _readTempFromPrev();
            if (temp == null) {
                result.err <- format(SI702X.ERROR_TEMP_READ, _i2c.readerror());
            } else {
                result.temperature = temp;
            }
        }

        return result;
    }

    // Starts a relative humidity measurement
    function _readRH(callback = null) {
        _i2c.write(_addr, SI702X.MEASURE_RH);
        local startTime = hardware.millis();

        if (callback == null) {
            local result = _i2c.read(_addr, "", 2);
            while (result == null && (hardware.millis() - startTime) < SI702X.TIMEOUT_MS) {
                result = _i2c.read(_addr, "", 2);
            }
            return result;
        } else {
            _pollForResult(startTime, callback);
        }
    }

    // Reads and returns the temperature value from the previous humidity measurement
    function _readTempFromPrev() {
        local rawTemp = _i2c.read(_addr, SI702X.READ_PREV_TEMP, 2);
        if (rawTemp) {
            return SI702X.TEMP_MULT * ((rawTemp[0] << 8) + rawTemp[1]) + SI702X.TEMP_ADD;
        } else {
            return null;
        }
    }

    // Polls the sensor for the result of a previously-initiated measurement
    // (gives up after TIMEOUT milliseconds)
    function _pollForResult(startTime, callback) {
        local result = _i2c.read(_addr, "", 2);
        if (result) {
            callback(result);
        } else if ((hardware.millis() - startTime) < SI702X.TIMEOUT_MS) {
            imp.wakeup(0, function() {
                _pollForResult(startTime, callback);
            }.bindenv(this));
        } else {
            // Timeout
            callback(null);
        }
    }

}
