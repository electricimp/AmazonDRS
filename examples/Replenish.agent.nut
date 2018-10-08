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

#require "Rocky.class.nut:2.0.1"
#require "AmazonDRS.agent.lib.nut:1.1.0"

// AmazonDRS library example:
// - authenticates the device on Amazon platform using the provided Client ID and Client Secret
// - executes the following cycle: places a test order, waits for 8 sec, cancels the order, waits for 12 sec
// - logs all responses received from the Amazon DRS

// Number of seconds to wait before cancel an order
const CANCEL_DELAY = 8;
// Number of seconds to wait before place an order again
const REPLENISH_DELAY = 12;

class ReplenishExample {
    _amazonDRSClient = null;
    _rocky = null;

    _deviceModel = null;
    _deviceSerial = null;
    _slotId = null;

    constructor(clientId, clientSecret, deviceModel, deviceSerial, slotId) {
        _amazonDRSClient = AmazonDRS(clientId, clientSecret);
        _rocky = Rocky();
        _deviceModel = deviceModel;
        _deviceSerial = deviceSerial;
        _slotId = slotId;
    }

    function start() {
        local testDevice = true;
        local nonLiveDevice = true;
        _amazonDRSClient.login(_rocky, _deviceModel, _deviceSerial, onAuthenticated.bindenv(this), null, testDevice, nonLiveDevice);
    }

    function onAuthenticated(error, response) {
        if (error != 0) {
            server.error("Error authenticating: code = " + error + " response = " + http.jsonencode(response));
            return;
        }
        server.log("Successfully authenticated!");
        server.log("Your Refresh Token is " + _amazonDRSClient.getRefreshToken());
        replenish();
    }

    function replenish() {
        _amazonDRSClient.replenish(_slotId, onReplenished.bindenv(this));
    }

    function onReplenished(error, response) {
        if (error != 0) {
            server.error("Error replenishing: code = " + error + " response = " + http.jsonencode(response));
            return;
        }
        server.log("An order has been placed. Response from server: " + http.jsonencode(response));
        imp.wakeup(CANCEL_DELAY, cancel.bindenv(this));
    }

    function cancel() {
        _amazonDRSClient.cancelTestOrder(_slotId, onCanceled.bindenv(this));
    }

    function onCanceled(error, response) {
        if (error != 0) {
            server.error("Error canceling: code = " + error + " response = " + http.jsonencode(response));
            return;
        }
        server.log("The order has been canceled. Response from server: " + http.jsonencode(response));
        imp.wakeup(REPLENISH_DELAY, replenish.bindenv(this));
    }
}

// RUNTIME
// ---------------------------------------------------------------------------------

// AMAZON DRS CONSTANTS
// ---------------------------------------------------------------------------------
const AMAZON_DRS_CLIENT_ID = "<YOUR_AMAZON_CLIENT_ID>";
const AMAZON_DRS_CLIENT_SECRET = "<YOUR_AMAZON_CLIENT_SECRET>";
const AMAZON_DRS_SLOT_ID = "<YOUR_AMAZON_SLOT_ID>";

const AMAZON_DRS_DEVICE_MODEL = "example_model";
const AMAZON_DRS_DEVICE_SERIAL = "ReplenishExample";

// Start Application
amazonDRS <- ReplenishExample(AMAZON_DRS_CLIENT_ID,
                              AMAZON_DRS_CLIENT_SECRET,
                              AMAZON_DRS_DEVICE_MODEL,
                              AMAZON_DRS_DEVICE_SERIAL,
                              AMAZON_DRS_SLOT_ID);
amazonDRS.start();
server.log("Log in please!");
