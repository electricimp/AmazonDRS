// MIT License
//
// Copyright 2018 Electric Imp
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

@include "github:electricimp/Rocky/Rocky.class.nut@v2.0.1"


class DummyTestCase extends ImpTestCase {
    _amazonDRSClient = null;

    function setUp() {
        _amazonDRSClient = AmazonDRS("clientId", "clientSecret");
    }

    function testLogin1() {
        _amazonDRSClient.login("deviceModel", "deviceSerial");
    }

    function testLogin2() {
        local onAuth = function (err, response) { };
        _amazonDRSClient.login("deviceModel", "deviceSerial", onAuth);
    }

    function testLogin3() {
        local onAuth = function (err, response) { };
        _amazonDRSClient.login("deviceModel", "deviceSerial", onAuth, true);
    }

    function testLoginLogin() {
        return Promise(function (resolve, reject) {
            _amazonDRSClient.login("deviceModel", "deviceSerial");
            local onAuth = function (err, response) {
                if (err == AMAZON_DRS_ERROR_AUTH_STARTED_ALREADY) {
                    return resolve();
                }
                return reject("AMAZON_DRS_ERROR_AUTH_STARTED_ALREADY error was expected!");
            }.bindenv(this);
            _amazonDRSClient.login("deviceModel", "deviceSerial", onAuth);
        }.bindenv(this));
    }

    function testSetGetRefreshToken() {
        _amazonDRSClient.setRefreshToken("refreshToken");
        this.assertTrue(_amazonDRSClient.getRefreshToken() == "refreshToken");
    }

    function testReplenish() {
        _amazonDRSClient.replenish("slotId");
        return Promise(function (resolve, reject) {
            _amazonDRSClient.replenish("slotId", function (err, response) {
                if (err == AMAZON_DRS_ERROR_NOT_AUTHENTICATED) {
                    return resolve();
                }
                return reject("AMAZON_DRS_ERROR_NOT_AUTHENTICATED error was expected!");
            }.bindenv(this));
        }.bindenv(this));
    }

    function testCancelTestOrder() {
        _amazonDRSClient.cancelTestOrder();
        _amazonDRSClient.cancelTestOrder("slotId");
        return Promise(function (resolve, reject) {
            _amazonDRSClient.cancelTestOrder("slotId", function (err, response) {
                if (err == AMAZON_DRS_ERROR_NOT_AUTHENTICATED) {
                    return resolve();
                }
                return reject("AMAZON_DRS_ERROR_NOT_AUTHENTICATED error was expected!");
            }.bindenv(this));
        }.bindenv(this));
    }

    function testSetDebug() {
        _amazonDRSClient.setDebug(true);
        _amazonDRSClient.setDebug(false);
    }
}