// Copyright (c) 2014 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class SI702X {
    static READ_RH      = "\xF5";
    static READ_TEMP    = "\xF3";
    static PREV_TEMP    = "\xE0";
    static RH_MULT      = 125.0/65536.0;
    static RH_ADD       = -6;
    static TEMP_MULT    = 175.72/65536.0;
    static TEMP_ADD     = -46.85;

    _i2c  = null;
    _addr  = null;

    constructor(i2c, addr = 0x80)
    {
        _i2c  = i2c;
        _addr = addr;
    }

    function readHumidity() {
        _i2c.write(_addr, READ_RH);
        local reading = _i2c.read(_addr, "", 2);
        while (reading == null) {
            reading = _i2c.read(_addr, "", 2);
        }
        local humidity = RH_MULT*((reading[0] << 8) + reading[1]) + RH_ADD;
        return humidity;
    }

    function readTemp() {
        _i2c.write(_addr, READ_TEMP);
        local reading = _i2c.read(_addr, "", 2);
        while (reading == null) {
            reading = _i2c.read(_addr, "", 2);
        }
        local temperature = TEMP_MULT*((reading[0] << 8) + reading[1]) + TEMP_ADD;
        return temperature;
    }

    function readPrevTemp() {
        _i2c.write(_addr, PREV_TEMP);
        local reading = _i2c.read(_addr, "", 2);
        local temperature = TEMP_MULT*((reading[0] << 8) + reading[1]) + TEMP_ADD;
        return temperature;
    }
}
