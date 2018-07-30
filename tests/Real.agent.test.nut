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


const AMAZON_DRS_CLIENT_ID = "@{AMAZON_DRS_CLIENT_ID}";
const AMAZON_DRS_CLIENT_SECRET = "@{AMAZON_DRS_CLIENT_SECRET}";
const AMAZON_DRS_REFRESH_TOKEN = "@{AMAZON_DRS_REFRESH_TOKEN}";
const AMAZON_DRS_SLOT_ID = "@{AMAZON_DRS_SLOT_ID}";

class RealTestCase extends ImpTestCase {
    _amazonDRSClient = null;

    function setUp() {
        _amazonDRSClient = AmazonDRS(AMAZON_DRS_CLIENT_ID, AMAZON_DRS_CLIENT_SECRET);
        _amazonDRSClient.setRefreshToken(AMAZON_DRS_REFRESH_TOKEN);
    }

    function testReplenishCancel() {
        return _replenish()
            .then(function (value) {
                return _cancelTestOrder();
            }.bindenv(this))
            .fail(function (reason) {
                server.error("Error code: " + reason);
                return Promise.reject(reason);
            }.bindenv(this));
    }

    function _replenish() {
        return Promise(function (resolve, reject) {
            _amazonDRSClient.replenish(AMAZON_DRS_SLOT_ID, function (err, response) {
                if (err == 0) {
                    return resolve();
                }
                return reject(err);
            }.bindenv(this));
        }.bindenv(this));
    }

    function _cancelTestOrder() {
        return Promise(function (resolve, reject) {
            _amazonDRSClient.cancelTestOrder(AMAZON_DRS_SLOT_ID, function (err, response) {
                if (err == 0) {
                    return resolve();
                }
                return reject(err);
            }.bindenv(this));
        }.bindenv(this));
    }
}