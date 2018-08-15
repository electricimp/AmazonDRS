[![Build Status](https://api.travis-ci.org/electricimp/AmazonDRS.svg?branch=master)](https://travis-ci.org/electricimp/AmazonDRS)

# AmazonDRS #

This library allows your agent code to work with the [Amazon Dash Replenishment Service](https://developer.amazon.com/dash-replenishment-service) via the [RESTful API](https://developer.amazon.com/docs/dash/replenish-endpoint.html).

This version of the library supports the following functionality:

- Device authentication on the Dash Replenishment Service
- Placing test orders for Amazon goods
- Canceling test orders
- Placing real orders for Amazon goods

**To add this library to your project, add** `#require "AmazonDRS.agent.lib.nut:1.0.0"` **to the top of your agent code.**

## Library Usage ##

### Prerequisites ###

Before using the library you need to have:

- An Amazon Developer account
- [Client ID and Secret of your LWA Security Profile](https://developer.amazon.com/docs/dash/create-a-security-profile.html)
- [A DRS device](https://developer.amazon.com/dash-replenishment/drs_console.html) (account is required)

### Authentication ###

This library needs a `Refresh Token` to be able to call the Amazon's DRS API.
The `Refresh Token` can be acquired with the [login()](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice) method. Also, it can be acquired with any other application-specific way and then passed in with the [setRefreshToken()](#setrefreshtokenrefreshtoken) method.

Every time you call the [login()](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice) method or the [setRefreshToken()](#setrefreshtokenrefreshtoken) method and this call finishes the library starts to use new `Refresh Token`.

The [login()](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice) method provides the following authentication flow:
1. A user opens the agent's URL in a browser
1. The library handles this request and redirects the user to the Amazon login page or to the Amazon device's settings page if the user is already logged in
1. The user sets up the device in the Amazon's UI
1. The Amazon's LWA redirects the user back to the agent's URL with an authorization code
1. The agent receives this code and acquires security tokens (`Refresh Token` and `Access Token`)

More about authentication [here](https://developer.amazon.com/docs/dash/lwa-web-api.html) and [here](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html).

**Note**: After each restart of the agent the `Refresh Token` should be passed in to the library. So if you don't want to go through the authentication steps again, you may save the token in the agent's persistent storage and set it with the [setRefreshToken()](#setrefreshtokenrefreshtoken) method after each restart of the agent. See [the provided example](#example-store-and-load-refresh-token).

### Test Orders ###

For testing purposes, Amazon DRS allows making [test orders](https://developer.amazon.com/docs/dash/test-device-purchases.html). Test orders are those that made by a DRS device authenticated as a test device. So it is determined at the step of authentication whether the device is for testing or not.
Due to this the [login()](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice) method has a parameter *testDevice*. But if you set a `Refresh Token` manually with the [setRefreshToken()](#setrefreshtokenrefreshtoken) method, only you know whether this token was obtained for testing or not and such *testDevice* parameter is not required here.

Only test orders can be canceled with the [cancelTestOrder()](#canceltestorderslotid-oncanceled) method.

### Callbacks ###

All requests that are made to the Amazon platform occur asynchronously. Every method that sends a request has an optional parameter which takes a callback function that will be executed when the operation is completed, whether successfully or not. The callback’s parameters are listed in the corresponding method description, but every callback has at least one parameter, *error*. If *error* is `0`, the operation has been executed successfully. Otherwise, *error* is a code of an error.

## AmazonDRS Class ##

### Constructor: AmazonDRS(*clientId, clientSecret*) ###

This method returns a new AmazonDRS instance.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *clientId* | String | Yes | `Client ID` of your LWA Security Profile. For information, please see [here](https://developer.amazon.com/docs/login-with-amazon/glossary.html#client_identifier). |
| *clientSecret* | String | Yes | `Client Secret` of your LWA Security Profile. For information, please see [here](https://developer.amazon.com/docs/login-with-amazon/glossary.html#client_secret). |

### login(*rocky, deviceModel, deviceSerial[, onAuthenticated[, route[, testDevice]]]*) ###

This method allows to authenticate the agent on the Amazon and get required security tokens. The method automatically sets the obtained tokens to be used for DRS API calls, so you do not need to call the [setRefreshToken()](#setrefreshtokenrefreshtoken) method. For more information, please read about [authentication](#authentication). 

You may call this method again only after the previous call has finished. The call is considered as finished only when the authentication flow described in the [authentication](#authentication) section is completed or an error occured.

Either this method or [setRefreshToken()](#setrefreshtokenrefreshtoken) should be called and authentication should be done before making any DRS-related requests.

This method uses the [Rocky library](https://github.com/electricimp/Rocky), so it requires an instance of Rocky to be passed in.
By default, the login endpoint's route is `"/"`. Please, do not redefine the endpoint used by this method in your application code to avoid conflicts.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *rocky* | [Rocky](https://github.com/electricimp/Rocky) | Yes | An instance of [Rocky](https://github.com/electricimp/Rocky). |
| *deviceModel* | String | Yes | `Device Model`. For information, please see [here](https://developer.amazon.com/docs/dash/lwa-web-api.html#integrate-with-the-lwa-sdk-for-javascript). |
| *deviceSerial* | String | Yes | `Device Serial`. For information, please see [here](https://developer.amazon.com/docs/dash/lwa-web-api.html#integrate-with-the-lwa-sdk-for-javascript). |
| *onAuthenticated* | Function | Optional | Callback called when the operation is completed or an error occurs. |
| *route* | String | Optional | The login endpoint's route. If not specified or `null`, the default route `"/"` is used. |
| *testDevice* | Boolean | Optional | `True` if it is a test device. `False` by default. For more information, please see [here](https://developer.amazon.com/docs/dash/test-device-purchases.html) and the [Test Orders section](#test-orders). |

The method returns nothing. A result of the operation may be obtained via the [onAuthenticated](#callback-onauthenticatederror-response) callback if specified in this method.

#### Callback: onAuthenticated(*error, response*) ####

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the authentication is successful, an [error code](#error-code) otherwise. See possible HTTP error codes [here](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html#access-token-errors). |
| *response* | Table | Key-value table with the response provided by Amazon server. May be `null`. [See here about the response format](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html#access-token-response). Also may contain error details described [here](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html#access-token-errors) and [here](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html#authorization-errors). |

#### Example ####

```
#require "Rocky.class.nut:2.0.1"
#require "AmazonDRS.agent.lib.nut:1.0.0"

const AMAZON_DRS_CLIENT_ID = "<YOUR_AMAZON_CLIENT_ID>";
const AMAZON_DRS_CLIENT_SECRET = "<YOUR_AMAZON_CLIENT_SECRET>";
const AMAZON_DRS_DEVICE_MODEL = "<YOUR_AMAZON_DEVICE_MODEL>";
const AMAZON_DRS_DEVICE_SERIAL = "<YOUR_AMAZON_DEVICE_SERIAL>";

testDevice <- true;
loginRoute <- "/login";

function onAuthenticated(error, response) {
    if (error != 0) {
        server.error("Error authenticating: code = " + error + " response = " + http.jsonencode(response));
        return;
    }
    server.log("Successfully authenticated!");
}

client <- AmazonDRS(AMAZON_DRS_CLIENT_ID, AMAZON_DRS_CLIENT_SECRET);
rocky <- Rocky();
client.login(rocky, AMAZON_DRS_DEVICE_MODEL, AMAZON_DRS_DEVICE_SERIAL, onAuthenticated.bindenv(this), loginRoute, testDevice);
```

### setRefreshToken(*refreshToken*) ###

This method allows setting a `Refresh Token` manually. For more information, please read about [authentication](#authentication). 

Either this method or [login()](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice) should be called and authentication should be done before making any DRS-related requests.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *refreshToken* | String | Yes | A `Refresh Token` used to acquire an `Access Token` and refresh it when expired. |

The method returns nothing.

#### Example ####

```
#require "AmazonDRS.agent.lib.nut:1.0.0"

const AMAZON_DRS_CLIENT_ID = "<YOUR_AMAZON_CLIENT_ID>";
const AMAZON_DRS_CLIENT_SECRET = "<YOUR_AMAZON_CLIENT_SECRET>";
const AMAZON_DRS_REFRESH_TOKEN = "<YOUR_AMAZON_VALID_REFRESH_TOKEN>";

client <- AmazonDRS(AMAZON_DRS_CLIENT_ID, AMAZON_DRS_CLIENT_SECRET);
client.setRefreshToken(AMAZON_DRS_REFRESH_TOKEN);
```

### getRefreshToken() ###

The method returns a string with the `Refresh Token` or `null` if it is not set.

### replenish(*slotId[, onReplenished]*) ###

This method places an order for a device/slot combination. For more information, please see [the Amazon DRS documentation](https://developer.amazon.com/docs/dash/replenish-endpoint.html).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *slotId* | String | Yes | ID of a slot to place an order for it. |
| *onReplenished* | Function | Optional | Callback called when the operation is completed or an error occurs. |

The method returns nothing. A result of the operation may be obtained via the [onReplenished](#callback-onreplenishederror-response) callback if specified in this method.

#### Callback: onReplenished(*error, response*) ####

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the operation is completed successfully, an [error code](#error-code) otherwise. See possible HTTP error codes [here](https://developer.amazon.com/docs/dash/replenish-endpoint.html#error-responses). |
| *response* | Table | Key-value table with the response provided by Amazon server. May be `null`. [See response example](https://developer.amazon.com/docs/dash/replenish-endpoint.html#response-example). Also may contain [error details](https://developer.amazon.com/docs/dash/replenish-endpoint.html#error-responses). |

#### Example ####

```
const AMAZON_DRS_SLOT_ID = "<YOUR_AMAZON_SLOT_ID>";

function onReplenished(error, response) {
    if (error != 0) {
        server.error("Error replenishing: code = " + error + " response = " + http.jsonencode(response));
        return;
    }
    server.log("An order has been placed. Response from server: " + http.jsonencode(response));
}

// It is supposed that the client has been authenticated with either login() method or setRefreshToken() method
client.replenish(AMAZON_DRS_SLOT_ID, onReplenished.bindenv(this));
```

### cancelTestOrder(*[slotId[, onCanceled]]*) ###

This method cancels test orders for one or all slots in the device. For more information, please see [the Amazon DRS documentation](https://developer.amazon.com/docs/dash/canceltestorder-endpoint.html).

The method can only be used for the orders made by a test device ([a device authenticated as a test one](https://developer.amazon.com/docs/dash/test-device-purchases.html)). The library does not check if your device authenticated as a test one or not, so you are responsible for this check. See the [Test Orders section](#test-orders).

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *slotId* | String | Optional | ID of a slot to be canceled. If is `null` or not specified, test orders for all slots in the device will be canceled. |
| *onCanceled* | Function | Optional | Callback called when the operation is completed or an error occurs. |

The method returns nothing. A result of the operation may be obtained via the [onCanceled](#callback-oncancelederror-response) callback if specified in this method.

#### Callback: onCanceled(*error, response*) ####

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the operation is completed successfully, an [error code](#error-code) otherwise. See possible HTTP error codes [here](https://developer.amazon.com/docs/dash/canceltestorder-endpoint.html#error-responses). |
| *response* | Table | Key-value table with the response provided by Amazon server. May be `null`. [See response example](https://developer.amazon.com/docs/dash/canceltestorder-endpoint.html#response-example). Also may contain [error details](https://developer.amazon.com/docs/dash/canceltestorder-endpoint.html#error-responses). |

#### Example ####

```
const AMAZON_DRS_SLOT_ID = "<YOUR_AMAZON_SLOT_ID>";

function onCanceled(error, response) {
    if (error != 0) {
        server.error("Error canceling: code = " + error + " response = " + http.jsonencode(response));
        return;
    }
    server.log("The order has been canceled. Response from server: " + http.jsonencode(response));
}

// It is supposed that client has been authenticated with either login() method or setRefreshToken() method
// as a test DRS device
client.cancelTestOrder(AMAZON_DRS_SLOT_ID, onCanceled.bindenv(this));
```

### setDebug(*value*) ###

This method enables (*value* is `true`) or disables (*value* is `false`) the library debug output (including error logging). It is disabled by default. The method returns nothing.

### Error code ###

An *Integer* error code which specifies a concrete error (if any) occured during an operation.

| Error Code | Description |
| --- | --- |
| 0 | No error. |
| 1-99 | [Internal errors of the HTTP API](https://developer.electricimp.com/api/httprequest/sendasync). |
| 100-999 | HTTP error codes from Amazon server. See methods' descriptions for more information. |
| 1000 | The client is not authenticated. E.g. `Refresh Token` is invalid or not set. |
| 1001 | The [login()](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice) method is already called. |
| 1010 | General error. |

## Examples ##

Working examples are provided in the [examples](./examples) directory and described [here](./examples/README.md).

The following example shows proper usage of [login()](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice), [setRefreshToken()](#setrefreshtokenrefreshtoken) and [getRefreshToken()](#getrefreshtoken) methods. It saves the `Refresh Token` in server-side persistent storage and then loads it to the library on each restart of the agent. Thus the user does not have to set up the device every time.

### Example: Store And Load Refresh Token ###

```
#require "Rocky.class.nut:2.0.1"
#require "AmazonDRS.agent.lib.nut:1.0.0"

const AMAZON_DRS_CLIENT_ID = "<YOUR_AMAZON_CLIENT_ID>";
const AMAZON_DRS_CLIENT_SECRET = "<YOUR_AMAZON_CLIENT_SECRET>";
const AMAZON_DRS_DEVICE_MODEL = "<YOUR_AMAZON_DEVICE_MODEL>";
const AMAZON_DRS_DEVICE_SERIAL = "<YOUR_AMAZON_DEVICE_SERIAL>";

function getStoredRefreshToken() {
    local persist = server.load();
    local amazonDRS = {};
    if ("amazonDRS" in persist) {
        amazonDRS = persist.amazonDRS;
    }
    if ("refreshToken" in amazonDRS) {
        server.log("Refresh Token found!");
        return amazonDRS.refreshToken;
    }
    return null;
}

client <- AmazonDRS(AMAZON_DRS_CLIENT_ID, AMAZON_DRS_CLIENT_SECRET);

refreshToken <- getStoredRefreshToken();
if (refreshToken != null) {
    client.setRefreshToken(refreshToken);
} else {
    function onAuthenticated(error, response) {
        if (error != 0) {
            server.error("Error authenticating: code = " + error + " response = " + http.jsonencode(response));
            return;
        }
        refreshToken = client.getRefreshToken();
        client.setRefreshToken(refreshToken);
        local persist = server.load();
        persist.amazonDRS <- { "refreshToken" : refreshToken };
        server.save(persist);
        server.log("Successfully authenticated!");
        server.log("Refresh Token saved!");
    }
    
    local testDevice = true;
    rocky <- Rocky();
    client.login(rocky, AMAZON_DRS_DEVICE_MODEL, AMAZON_DRS_DEVICE_SERIAL, onAuthenticated.bindenv(this), null, testDevice);
    server.log("Log in please!");
}
```

## Testing ##

Tests for the library are provided in the [tests](./tests) directory and described [here](./tests/README.md).

## License ##

The AmazonDRS library is licensed under the [MIT License](./LICENSE).
