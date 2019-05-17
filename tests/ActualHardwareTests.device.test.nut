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


// Requires Hardware with Si702x temperature/humidity sensor
// Tests configured for Nora - impFarm device's C or J
class ActualHardwareTests extends ImpTestCase {

    _i2c = null;

    function setUp() {
        // Nora i2c for sensors
        _i2c = hardware.i2c89;
        _i2c.configure(CLOCK_SPEED_400_KHZ);
        return "Actual hardware test setup complete.";
    }

    function testSyncRead() {
        local tempHumid = Si702x(_i2c);
        local reading = tempHumid.read();

        // Expect valid reading
        assertTrue(!("err" in reading), "Reading had unexpected error.");
        assertEqual("float", typeof reading.temperature, "Temperature reading was not a float");
        assertEqual("float", typeof reading.humidity, "Humidity reading was not a float");
        // params: actual, from, to, msg
        assertBetween(reading.temperature, 0, 40, "Temperature not in expected range: " + reading.temperature);
        assertBetween(reading.humidity, -1, 101, "Humidity not in expected range: " + reading.humidity);
        return "Sync read test complete.";
    }

    function testAsyncRead() {
        return Promise(function(resolve, reject) {
            local tempHumid = Si702x(_i2c);
            tempHumid.read(function(reading) {
                assertTrue(!("err" in reading), "Reading had unexpected error");
                assertEqual("float", typeof reading.temperature, "Temperature reading was not a float");
                assertEqual("float", typeof reading.humidity, "Humidity reading was not a float");
                // params: actual, from, to, msg
                assertBetween(reading.temperature, 0, 40, "Temperature not in expected range: " + reading.temperature);
                assertBetween(reading.humidity, -1, 101, "Humidity not in expected range: " + reading.humidity);
                return resolve("Async read test complete");
            }.bindenv(this))
        }.bindenv(this))
    }

    function tearDown() {
        return "Actual hardware tests finished.";
    }

}
