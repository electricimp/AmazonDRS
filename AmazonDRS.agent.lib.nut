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


// AmazonDRS is an Electric Imp agent-side library for interfacing with the Amazon Dash Replenishment Service via the RESTful API.

// Error codes
const AMAZON_DRS_ERROR_NOT_AUTHENTICATED    = 1000;
const AMAZON_DRS_ERROR_LOGIN_ALREADY_CALLED = 1001;
const AMAZON_DRS_ERROR_GENERAL              = 1010;

class AmazonDRS {

    _debugEnabled = false;

    _loginEnabled = false;

    _clientId = null;
    _clientSecret = null;

    _refreshToken = null;
    _accessToken = null;
    // Timestamp of token's expiration
    _accessTokenExpiration = 0;

    // AmazonDRS class constructor.
    //
    // Parameters:
    //     clientId : String        Client ID of your LWA Security Profile.
    //     clientSecret : String    Client Secret of your LWA Security Profile.
    //
    // Returns:                         AmazonDRS instance created.
    constructor(clientId, clientSecret) {
        // We consider the Access token expired 5 seconds earlier than it really expires
        const EXPIRATION_TIME_MARGIN = 5;
        const REPLENISH_ENDPOINT = "https://dash-replenishment-service-na.amazon.com/replenish/";
        const CANCEL_ALL_TEST_ORDERS_ENDPOINT = "https://dash-replenishment-service-na.amazon.com/testOrders";
        const CANCEL_TEST_ORDER_ENDPOINT = "https://dash-replenishment-service-na.amazon.com/testOrders/slots/";
        const LOGIN_ENDPOINT = "/";
        const LWA_ENDPOINT = "https://www.amazon.com/ap/oa";
        const OAUTH_TOKEN_ENDPOINT = "https://api.amazon.com/auth/o2/token";

        _clientId = clientId;
        _clientSecret = clientSecret;
    }

    // Allows to authenticate the agent on the Amazon and get required security tokens.
    // The method automatically sets the obtained tokens to be used for DRS API calls.
    //
    // Parameters:
    //     rocky : Rocky                An instance of Rocky.
    //     deviceModel : String         Device Model.
    //     deviceSerial : String        Device Serial.
    //     onAuthenticated : Function   Callback called when the operation is completed or an error happens.
    //          (optional)              The callback signature:
    //                                  onAuthenticated(error, response), where
    //                                      error : Integer     0 if the authentication is successful, an error code otherwise.
    //                                      response : Table    Key-value table with the response provided by Amazon server. May be null.
    //     testDevice : Boolean         True if it is a test device. False by default.
    //          (optional)
    //
    // Returns:                         Nothing.
    function login(rocky, deviceModel, deviceSerial, onAuthenticated = null, testDevice = false) {
        if (_loginEnabled) {
            onAuthenticated && onAuthenticated(AMAZON_DRS_ERROR_LOGIN_ALREADY_CALLED, null);
            return;
        }

        local authDone = function (error, resp) {
            _loginEnabled = false;
            _undefineLoginEndpoint(rocky);
            onAuthenticated && onAuthenticated(error, resp);
        }.bindenv(this);

        _loginEnabled = true;
        _defineLoginEndpoint(rocky, deviceModel, deviceSerial, testDevice, authDone);
    }

    // Allows to set a Refresh Token manually.
    //
    // Parameters:
    //     refreshToken : String        A Refresh Token used to acquire an Access Token and refresh it when expired.
    //
    // Returns:                         Nothing.
    function setRefreshToken(refreshToken) {
        // Invalidate the existing Access Token
        _accessToken = null;
        _accessTokenExpiration = 0;
        _refreshToken = refreshToken;
    }

    // Returns a string with the Refresh Token or null if it is not set.
    //
    // Returns:                         A string with the Refresh Token or null if it is not set.
    function getRefreshToken() {
        return _refreshToken;
    }

    // Places an order for a device/slot combination.
    //
    // Parameters:
    //     slotId : String              ID of a slot to place an order for it.
    //     onReplenished : Function     Callback called when the operation is completed or an error happens.
    //          (optional)              The callback signature:
    //                                  onReplenished(error, response), where
    //                                      error : Integer     0 if the authentication is successful, an error code otherwise.
    //                                      response : Table    Key-value table with the response provided by Amazon server. May be null.
    //
    // Returns:                         Nothing.
    function replenish(slotId, onReplenished = null) {
        if (_refreshToken == null) {
            _logError("Refresh token is not set!");
            onReplenished && onReplenished(AMAZON_DRS_ERROR_NOT_AUTHENTICATED, null);
            return;
        }
        if (_isAccessTokenExpired()) {
            _log("Access token is expired");
            local onRefreshed = function (err, respBody) {
                if (err != 0 || _isAccessTokenExpired()) {
                    onReplenished && onReplenished(AMAZON_DRS_ERROR_NOT_AUTHENTICATED, respBody);
                } else {
                    _requestReplenish(slotId, onReplenished);
                }
            }.bindenv(this);

            _refreshAccessToken(onRefreshed);
            return;
        }

        _requestReplenish(slotId, onReplenished);
    }

    // Cancels test orders for one or all slots in the device.
    //
    // Parameters:
    //     slotId : String              ID of a slot to be canceled.
    //          (optional)              If is null or not specified, test orders for all slots in the device will be canceled.
    //     onCanceled : Function        Callback called when the operation is completed or an error happens.
    //          (optional)              The callback signature:
    //                                  onCanceled(error, response), where
    //                                      error : Integer     0 if the authentication is successful, an error code otherwise.
    //                                      response : Table    Key-value table with the response provided by Amazon server. May be null.
    //
    // Returns:                         Nothing.
    function cancelTestOrder(slotId = null, onCanceled = null) {
        if (_refreshToken == null) {
            onCanceled && onCanceled(AMAZON_DRS_ERROR_NOT_AUTHENTICATED, null);
            return;
        }
        if (_isAccessTokenExpired()) {
            _log("Access token is expired");
            local onRefreshed = function (err, respBody) {
                if (err != 0 || _isAccessTokenExpired()) {
                    onCanceled && onCanceled(AMAZON_DRS_ERROR_NOT_AUTHENTICATED, respBody);
                } else {
                    _requestCancelOrder(slotId, onCanceled);
                }
            }.bindenv(this);

            _refreshAccessToken(onRefreshed);
            return;
        }

        _requestCancelOrder(slotId, onCanceled);
    }

    // Enables or disables the client debug output. Disabled by default.
    //
    // Parameters:
    //     value : Boolean              true to enable, false to disable
    //
    // Returns:                         Nothing.
    function setDebug(value) {
        _debugEnabled = value;
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _requestReplenish(slotId, onReplenished) {
        local headers = {
            "Authorization" : "Bearer " + _accessToken,
            "x-amzn-accept-type" : "com.amazon.dash.replenishment.DrsReplenishResult@1.0",
            "x-amzn-type-version" : "com.amazon.dash.replenishment.DrsReplenishInput@1.0"
        };

        local req = http.post(REPLENISH_ENDPOINT + slotId, headers, "");

        local sent = function (resp) {
            _onSent(resp, onReplenished);
        }.bindenv(this);

        req.sendasync(sent);
    }

    function _requestCancelOrder(slotId, onCanceled) {
        local headers = {
            "Authorization" : "Bearer " + _accessToken,
            "x-amzn-accept-type" : "com.amazon.dash.replenishment.DrsCancelTestOrdersResult@1.0",
            "x-amzn-type-version" : "com.amazon.dash.replenishment.DrsCancelTestOrdersInput@1.0"
        };

        local req = null;

        if (slotId != null) {
            req = http.httpdelete(CANCEL_TEST_ORDER_ENDPOINT + slotId, headers);
        } else {
            req = http.httpdelete(CANCEL_ALL_TEST_ORDERS_ENDPOINT, headers);
        }

        local sent = function (resp) {
            _onSent(resp, onCanceled);
        }.bindenv(this);

        req.sendasync(sent);
    }

    function _defineLoginEndpoint(rocky, deviceModel, deviceSerial, testDevice, callback) {
        // Define login endpoint for GET requests to the agent URL
        rocky.get(LOGIN_ENDPOINT, function(context) {
            if ("error" in context.req.query) {
                callback && callback(AMAZON_DRS_ERROR_GENERAL, context.req.query)
                context.send(500, "Error: " + http.jsonencode(context.req.query));
                return;
            }
            // Check if an authorization code was passed in
            if (!("code" in context.req.query)) {
                // If it wasn't, redirect to login service
                _redirectToLWA(deviceModel, deviceSerial, context, testDevice);
                return;
            }

            _log("Authorization code has been received");
            local onAccessTokenReceived = function(err, respBody) {
                _onAccessTokenReceived(err, respBody, context, callback);
            }.bindenv(this);

            // Exchange the authorization code for an access token
            _getAccessToken(context.req.query["code"], onAccessTokenReceived);
        }.bindenv(this));
    }

    function _undefineLoginEndpoint(rocky) {
        rocky.get(LOGIN_ENDPOINT, function(context) {
            context.send(503, "Authentication is finished. You may reactivate it with login() method.");
        }.bindenv(this));
    }

    function _onAccessTokenReceived(err, respBody, context, callback) {
        local errMsg = null;
        if (err != 0) {
            errMsg = "Error authenticating: code = " + err + ", body = " + http.jsonencode(respBody);
        } else if ("access_token" in respBody && "expires_in" in respBody && "refresh_token" in respBody) {
            _accessToken = respBody.access_token;
            _accessTokenExpiration = time() + respBody.expires_in - EXPIRATION_TIME_MARGIN;
            _refreshToken = respBody.refresh_token;
        } else {
            err = AMAZON_DRS_ERROR_GENERAL;
            errMsg = "Error authenticating: Access and Refresh tokens and Expiration time were expected in the response";
        }

        if (err != 0) {
            _logError(errMsg);
            callback && callback(err, respBody);
            context.send(500, errMsg);
            return;
        }

        _log("Access and Refresh tokens have been received successfully");
        callback && callback(0, respBody);
        // Finally - inform the user we're done!
        context.send(200, "Authentication complete - you may now close this window");
    }

    function _redirectToLWA(deviceModel, deviceSerial, context, testDevice) {
        local location = LWA_ENDPOINT;
        local params = {
            "client_id" : _clientId,
            "scope" : "dash:replenish",
            "scope_data" : http.jsonencode({
                "dash:replenish" : {
                    "device_model" : deviceModel,
                    "serial" : deviceSerial,
                    "is_test_device" : testDevice
                }
            }),
            "response_type" : "code",
            "redirect_uri" : http.agenturl()
        };
        location += "?" + http.urlencode(params);
        context.setHeader("Location", location);
        context.send(302, "Found");
        _log("User has been redirected to the Amazon's setup page");
    }

    function _getAccessToken(code, callback) {
        // Send request with an authorization code
        _oauthTokenRequest("authorization_code", code, callback);
    }

    function _isAccessTokenExpired() {
        return _accessTokenExpiration <= time();
    }

    function _refreshAccessToken(callback) {
        _log("Refreshing the Access token...");
        local refreshed = function (err, respBody) {
            if (err != 0) {
                _logError("Error refreshing Access token: code = " + err + ", body = " + http.jsonencode(respBody));
            } else if ("access_token" in respBody && "expires_in" in respBody) {
                _accessToken = respBody.access_token;
                _accessTokenExpiration = time() + respBody.expires_in - EXPIRATION_TIME_MARGIN;
                _log("The Access token has been refreshed successfully")
            } else {
                err = AMAZON_DRS_ERROR_GENERAL;
                _logError("Error refreshing Access token: Access token and Expiration time were expected in the response");
            }

            callback && callback(err, respBody);
        }.bindenv(this);

        // Send request with refresh token
        _oauthTokenRequest("refresh_token", _refreshToken, refreshed);
    }

    function _oauthTokenRequest(type, token, callback) {
        local url = OAUTH_TOKEN_ENDPOINT;
        local headers = { "Content-Type": "application/x-www-form-urlencoded" };
        local data = {
            "grant_type": type,
            "client_id": _clientId,
            "client_secret": _clientSecret,
        };

        if (type == "authorization_code") {
            data.code <- token;
            data.redirect_uri <- http.agenturl();
        } else if (type == "refresh_token") {
            data.refresh_token <- token;
        } else {
            throw "Unknown grant_type";
        }

        local body = http.urlencode(data);

        local sent = function(resp) {
            _onSent(resp, callback);
        }.bindenv(this);

        http.post(url, headers, body).sendasync(sent);
    }

    function _onSent(resp, callback) {
        local err = 0;
        local respBody = null;

        if (!_statusIsOk(resp.statuscode)) {
            err = resp.statuscode;
        }

        try {
            respBody = http.jsondecode(resp.body);
        } catch (e) {
            if (err == 0) {
                err = AMAZON_DRS_ERROR_GENERAL;
            }
            _logError("Response body is not a valid JSON: " + e);
        }

        callback && callback(err, respBody);
    }

    // Check HTTP status
    function _statusIsOk(status) {
        return status / 100 == 2;
    }

    // Metafunction to return class name when typeof <instance> is run
    function _typeof() {
        return "AmazonDRS";
    }

     // Information level logger
    function _log(txt) {
        if (_debugEnabled) {
            server.log("[" + (typeof this) + "] " + txt);
        }
    }

    // Error level logger
    function _logError(txt) {
        if (_debugEnabled) {
            server.error("[" + (typeof this) + "] " + txt);
        }
    }
}
