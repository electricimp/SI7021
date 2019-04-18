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

@include __PATH__+"/StubbedI2C.device.nut"

const SI702X_DEFAULT_I2C_ADDR = 0x80;

class StubbedHardwareTests extends ImpTestCase {

    _i2c       = null;
    _tempHumid = null;

    function setUp() {
        _i2c = StubbedI2C();
        _i2c.configure(CLOCK_SPEED_400_KHZ);
        _tempHumid = Si702x(_i2c);
        return "Stubbed hardware test setup complete.";
    }

    function testConstructorDefaultParams() {
        local th = Si702x(_i2c);
        assertEqual(SI702X_DEFAULT_I2C_ADDR, th._addr, "Defult i2c address did not match expected");
        return "Constructor default params test complete.";
    }

    function testConstructorOptionalParams() {
        local customAddr = 0xBA;
        local th = Si702x(_i2c, customAddr);
        assertEqual(customAddr, th._addr, "Non default i2c address did not match expected");
        return "Constructor optional params test complete.";
    }

    function testInit() {
        _i2c._clearWriteBuffer();
        _tempHumid.init();

        local expectedData = "\xFE";
        local i2cWriteBuffer = _i2c._getWriteBuffer(SI702X_DEFAULT_I2C_ADDR);
        assertEqual(i2cWriteBuffer, expectedData, "Init function did not write the expected payload to the default address");
        _i2c._clearWriteBuffer();
        return "Init function test complete.";
    }

    function testHumidityReadSyncFailed() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(_addr, "", 2);
        // multiple i2c reads return null after 100ms

        local expResult = null;
        local regAddr = "";
        _i2c._clearReadResp();
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, regAddr, expResult);

        local start = hardware.millis();
        local result = _tempHumid._readRH();
        local end = hardware.millis();
        assertEqual(expResult, result, "Sync humidity failure reading did not match expected");
        assertClose(SI702X.TIMEOUT_MS, end - start, 50, "Reading time not within expected range");

        _i2c._clearReadResp();
        _i2c._clearWriteBuffer();
        return "Sync humidity expected failed reading test complete";
    }

    function testHumidityReadSyncSuccessful() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(_addr, "", 2);
        // multiple i2c reads return null after 100ms

        local expResult = "\x50\x96";
        local regAddr = "";
        _i2c._clearReadResp();
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, regAddr, expResult);

        local result = _tempHumid._readRH();
        assertEqual(expResult, result, "Sync humidity successful reading did not match expected");

        _i2c._clearReadResp();
        _i2c._clearWriteBuffer();
        return "Sync humidity expected successful reading test complete";
    }

    function testHumidityReadAsyncFailed() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(_addr, "", 2);
        // multiple i2c reads for 100ms pass null to callback

        return Promise(function(resolve, reject) {
            local expResult = null;
            local regAddr = "";
            _i2c._clearReadResp();
            _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, regAddr, expResult);

            local start = hardware.millis();
            _tempHumid._readRH(function(result) {
                local end = hardware.millis();
                assertEqual(expResult, result, "Sync humidity failure reading did not match expected");
                assertClose(SI702X.TIMEOUT_MS, end - start, 50, "Reading time not within expected range");

                _i2c._clearReadResp();
                _i2c._clearWriteBuffer();
                return resolve("Async humidity expected failed reading test complete");
            }.bindenv(this));

        }.bindenv(this))
    }

    function testHumidityReadAsyncSuccessful() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(_addr, "", 2);
        // multiple i2c reads for 100ms pass null to callback

        return Promise(function(resolve, reject) {
            local expResult = "\x50\x96";
            local regAddr = "";
            _i2c._clearReadResp();
            _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, regAddr, expResult);

            _tempHumid._readRH(function(result) {
                assertEqual(expResult, result, "Sync humidity failure reading did not match expected");

                _i2c._clearReadResp();
                _i2c._clearWriteBuffer();
                return resolve("Async humidity expected failed reading test complete");
            }.bindenv(this));

        }.bindenv(this))

        // Test Success reading (sync/async):
        // i2c read returns string "\x50\x96" 33.3486, "\x50\x8a" 33.3257
    }

    function testTempReadFailed() {
        // Command:
        // _i2c.read(0x80, "\xE0", 2);

        local expResult = null;
        local regAddr = "\xE0";
        _i2c._clearReadResp();
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, regAddr, expResult);

        local result = _tempHumid._readTempFromPrev();
        assertEqual(expResult, result, "Temperature failure reading did not match expected");

        _i2c._clearReadResp();
        return "Temperature expected failed reading test complete";
    }

    function testTempReadSuccessful() {
        // Command:
        // _i2c.read(0x80, "\xE0", 2);

        local expRawResult = "\x68\xa8";
        local expProcessedResult = 24.98670959472656384;
        local regAddr = "\xE0";
        _i2c._clearReadResp();
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, regAddr, expRawResult);

        local result = _tempHumid._readTempFromPrev();
        assertEqual(expProcessedResult, result, "Temperature successful reading did not match expected");

        _i2c._clearReadResp();
        return "Temperature expected successful reading test complete";
    }

    function testTempHumidReadSyncFailedTemp() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(0x80, "", 2);
        // _i2c.read(0x80, "\xE0", 2);

        local tempRegAddr = "\xE0";
        local expTemp = null;

        local humidRegAddr = "";
        local expRawHumid = "\x5f\x9e";
        local expProcessedHumid = 40.68807983398437376;

        _i2c._clearReadResp();
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, tempRegAddr, expTemp);
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, humidRegAddr, expRawHumid);

        local reading = _tempHumid.read();

        // Expect valid reading
        assertTrue(("err" in reading), "Reading missing expected error.");
        assertEqual(format(SI702X.ERROR_TEMP_READ, 0), reading.err, "Reading had unexpected error: " + reading.err);
        assertEqual("float", typeof reading.humidity, "Humidity reading was not a float");
        assertEqual(expTemp, reading.temperature, "Temperature not expected value: " + reading.temperature);
        assertEqual(expProcessedHumid, reading.humidity, "Humidity not expected value: " + reading.humidity);

        _i2c._clearReadResp();
        _i2c._clearWriteBuffer();
        return "Sync failed with no temp read test complete.";
    }

    function testTempHumidReadSyncFailedHumid() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(0x80, "", 2);
        // _i2c.read(0x80, "\xE0", 2);

        local tempRegAddr = "\xE0";
        local expTemp = null;

        local humidRegAddr = "";
        local expHumid = null;

        _i2c._clearReadResp();
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, tempRegAddr, expTemp);
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, humidRegAddr, expHumid);

        local reading = _tempHumid.read();

        // Expect valid reading
        assertTrue(("err" in reading), "Reading missing expected error.");
        assertEqual(SI702X.ERROR_READ_TIMEOUT, reading.err, "Reading had unexpected error: " + reading.err);
        assertEqual(expTemp, reading.temperature, "Temperature not expected value: " + reading.temperature);
        assertEqual(expHumid, reading.humidity, "Humidity not expected value: " + reading.humidity);

        _i2c._clearReadResp();
        _i2c._clearWriteBuffer();
        return "Sync failed with no humid read test complete.";
    }

    function testTempHumidReadSyncSuccessful() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(0x80, "", 2);
        // _i2c.read(0x80, "\xE0", 2);

        local tempRegAddr = "\xE0";
        local expRawTemp = "\x68\xa8";
        local expProcessedTemp = 24.98670959472656384;

        local humidRegAddr = "";
        local expRawHumid = "\x5f\x9e";
        local expProcessedHumid = 40.68807983398437376;

        _i2c._clearReadResp();
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, tempRegAddr, expRawTemp);
        _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, humidRegAddr, expRawHumid);

        local reading = _tempHumid.read();

        // Expect valid reading
        assertTrue(!("err" in reading), "Reading had unexpected error.");
        assertEqual("float", typeof reading.temperature, "Temperature reading was not a float");
        assertEqual("float", typeof reading.humidity, "Humidity reading was not a float");
        assertEqual(expProcessedTemp, reading.temperature, "Temperature not expected value: " + reading.temperature);
        assertEqual(expProcessedHumid, reading.humidity, "Humidity not expected value: " + reading.humidity);

        _i2c._clearReadResp();
        _i2c._clearWriteBuffer();
        return "Sync successful read test complete.";
    }

    function testTempHumidReadAsyncFailedTemp() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(0x80, "", 2);
        // _i2c.read(0x80, "\xE0", 2);

        return Promise(function(resolve, reject) {
            local tempRegAddr = "\xE0";
            local expTemp = null;

            local humidRegAddr = "";
            local expRawHumid = "\x5f\x9e";
            local expProcessedHumid = 40.68807983398437376;

            _i2c._clearReadResp();
            _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, tempRegAddr, expTemp);
            _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, humidRegAddr, expRawHumid);

            _tempHumid.read(function(reading) {
                // Expect valid reading
                assertTrue(("err" in reading), "Reading missing expected error.");
                assertEqual(format(SI702X.ERROR_TEMP_READ, 0), reading.err, "Reading had unexpected error: " + reading.err);
                assertEqual("float", typeof reading.humidity, "Humidity reading was not a float");
                assertEqual(expTemp, reading.temperature, "Temperature not expected value: " + reading.temperature);
                assertEqual(expProcessedHumid, reading.humidity, "Humidity not expected value: " + reading.humidity);

                _i2c._clearReadResp();
                _i2c._clearWriteBuffer();
                return resolve("Async failed with no temp read test complete.");
            }.bindenv(this));

        }.bindenv(this))
    }

    function testTempHumidReadAsyncFailedHumid() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(0x80, "", 2);
        // _i2c.read(0x80, "\xE0", 2);

        return Promise(function(resolve, reject) {

            local tempRegAddr = "\xE0";
            local expTemp = null;

            local humidRegAddr = "";
            local expHumid = null;

            _i2c._clearReadResp();
            _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, tempRegAddr, expTemp);
            _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, humidRegAddr, expHumid);

            _tempHumid.read(function(reading) {
                // Expect valid reading
                assertTrue(("err" in reading), "Reading missing expected error.");
                assertEqual(SI702X.ERROR_READ_TIMEOUT, reading.err, "Reading had unexpected error: " + reading.err);
                assertEqual(expTemp, reading.temperature, "Temperature not expected value: " + reading.temperature);
                assertEqual(expHumid, reading.humidity, "Humidity not expected value: " + reading.humidity);

                _i2c._clearReadResp();
                _i2c._clearWriteBuffer();
                return resolve("Async failed with no humid read test complete.");
            }.bindenv(this));

        }.bindenv(this))
    }

    function testTempHumidReadAsyncSuccessful() {
        // Commands:
        // _i2c.write(0x80, "\xF5");
        // _i2c.read(0x80, "", 2);
        // _i2c.read(0x80, "\xE0", 2);

        return Promise(function(resolve, reject) {
            local tempRegAddr = "\xE0";
            local expRawTemp = "\x68\xa8";
            local expProcessedTemp = 24.98670959472656384;

            local humidRegAddr = "";
            local expRawHumid = "\x5f\x9e";
            local expProcessedHumid = 40.68807983398437376;

            _i2c._clearReadResp();
            _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, tempRegAddr, expRawTemp);
            _i2c._setReadResp(SI702X_DEFAULT_I2C_ADDR, humidRegAddr, expRawHumid);

            _tempHumid.read(function(reading) {
                // Expect valid reading
                assertTrue(!("err" in reading), "Reading had unexpected error.");
                assertEqual("float", typeof reading.temperature, "Temperature reading was not a float");
                assertEqual("float", typeof reading.humidity, "Humidity reading was not a float");
                assertEqual(expProcessedTemp, reading.temperature, "Temperature not expected value: " + reading.temperature);
                assertEqual(expProcessedHumid, reading.humidity, "Humidity not expected value: " + reading.humidity);

                _i2c._clearReadResp();
                _i2c._clearWriteBuffer();
                return resolve("Async successful read test complete.");
            }.bindenv(this));
        }.bindenv(this))
    }

    function tearDown() {
        return "Stubbed hardware tests finished.";
    }

}
