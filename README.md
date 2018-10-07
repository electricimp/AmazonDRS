# Amazon DRS #

[![Build Status](https://api.travis-ci.org/electricimp/AmazonDRS.svg?branch=master)](https://travis-ci.org/electricimp/AmazonDRS)

This library allows your agent code to work with the [Amazon Dash Replenishment Service (DRS)](https://developer.amazon.com/dash-replenishment-service) via its [REST API](https://developer.amazon.com/docs/dash/replenish-endpoint.html).

This version of the library supports the following functionality:

- Device authentication on the Dash Replenishment Service.
- Placing test orders for Amazon goods.
- Canceling test orders.
- Placing real orders for Amazon goods.

**To add this library to your project, add** `#require "AmazonDRS.agent.lib.nut:1.1.0"` **to the top of your agent code.**

## Library Usage ##

### Prerequisites ###

Before using the library you need to have:

- An Amazon Developer account.
- The Client ID and Secret of your [LWA Security Profile](https://developer.amazon.com/docs/dash/create-a-security-profile.html).
- [A DRS device](https://developer.amazon.com/dash-replenishment/drs_console.html).

### Authentication ###

The library requires a Refresh Token to be able to call the Amazon DRS API. The Refresh Token can be acquired with [*login()*](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice-nonlivedevice). It can also be acquired in any other application-specific way and then passed to the class instance via [*setRefreshToken()*](#setrefreshtokenrefreshtoken).

Every time you call [*login()*](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice-nonlivedevice) or [*setRefreshToken()*](#setrefreshtokenrefreshtoken), the library starts to use a new Refresh Token.

The [*login()*](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice-nonlivedevice) method provides the following authentication flow:
1. A user opens the agent's URL in a browser.
1. The library handles this request and redirects the user to the Amazon login page, or to the Amazon device's settings page if the user is already logged in.
1. The user sets up the device in the Amazon UI.
1. The Amazon LWA redirects the user back to the agent's URL and provides an authorization code.
1. The agent receives this code and uses it to acquire the required security tokens (Refresh Token and Access Token).

You can read more about authentication [here](https://developer.amazon.com/docs/dash/lwa-web-api.html) and [here](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html).

**Note** The Refresh Token must be passed in to the library every time the agent restarts. If you don't want to go through the above authentication steps again, save the Token in the agent's persistent storage and set it with [*setRefreshToken()*](#setrefreshtokenrefreshtoken) after each agent restart. Please see [the provided example](#examples) for more details.

### Test Orders ###

For testing purposes, Amazon DRS allows you to submit [test orders](https://developer.amazon.com/docs/dash/test-device-purchases.html). Test orders are those made by a DRS device authenticated as a test device.

As such, [*login()*](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice-nonlivedevice) has a parameter, *testDevice*, which takes a boolean value indicating whether the device is a test device. However, if you set a Refresh Token manually with [*setRefreshToken()*](#setrefreshtokenrefreshtoken), only you know whether this token was obtained for testing or not and so *testDevice* is not required in this case.

Only test orders can be canceled with [*cancelTestOrder()*](#canceltestorderslotid-oncanceled).

### Non-live devices ###

Currently DRS devices exist in either one of two states:
 
- **Non-live (Pre-production)**. Non-live devices are devices that are created in our DRS developer portal but have not yet passed certification and have not launched to customers. You can still edit your device in the developer portal for device details, ASIN list details, etc.
 
- **Live**. Live devices are devices that have been fully certified and put into production. Live devices cannot be edited at all because of potential impacts to customers.

If your device is **non-live**, you must pass `true` as a *nonLiveDevice* parameter in to [*login()*](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice-nonlivedevice). However, if you set a Refresh Token manually with [*setRefreshToken()*](#setrefreshtokenrefreshtoken), only you know whether this token was obtained for **live** device or not and so *nonLiveDevice* is not required in this case.

### Callbacks ###

All requests that are made to the Amazon platform occur asynchronously. Every method that sends a request has an optional parameter which takes a callback function that will be executed when the operation is completed, whether successfully or not. The callback’s parameters are listed in the corresponding method description, but every callback has at least one parameter, *error*. If *error* is `0`, the operation has been executed successfully. Otherwise, *error* is a non-zero error code.

### Error Codes ###

Error codes are integers which specify a concrete error which occurred during an operation.

| Error Code | Description |
| --- | --- |
| 0 | No error |
| 1-99 | [Internal errors of the HTTP API](https://developer.electricimp.com/api/httprequest/sendasync) |
| 100-999 | HTTP error codes from Amazon server. See methods' descriptions for more information |
| 1000 | The client is not authenticated. For example, the Refresh Token is invalid or not set |
| 1001 | The [*login()*](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice-nonlivedevice) method has already been called |
| 1010 | General error |

## AmazonDRS Class Usage ##

### Constructor: AmazonDRS(*clientId, clientSecret*) ###

This method returns a new AmazonDRS instance.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *clientId* | String | Yes | The Client ID of your LWA Security Profile. For more information, please see [the Amazon documentation](https://developer.amazon.com/docs/login-with-amazon/glossary.html#client_identifier) |
| *clientSecret* | String | Yes | The Client Secret of your LWA Security Profile. For information, please see [the Amazon documentation](https://developer.amazon.com/docs/login-with-amazon/glossary.html#client_secret) |

### login(*rocky, deviceModel, deviceSerial[, onAuthenticated][, route][, testDevice][, nonLiveDevice]*) ###

This method allows you to authenticate the agent with Amazon and retrieve the required security tokens. The method automatically sets the obtained tokens to be used for DRS API calls, so you do not need to call [*setRefreshToken()*](#setrefreshtokenrefreshtoken) after *login()*. For more information, please read the [authentication](#authentication) section. 

You may re-call this method only after the previous call has finished. The call is considered to be finished only when the authentication flow described in the [authentication](#authentication) section above is completed or an error occured. Authentication should be performed before making any DRS-related requests.

This method uses the [Rocky library](https://github.com/electricimp/Rocky), so it requires an instance of Rocky.

By default, the login endpoint's route is `"/"`. Please do not redefine the endpoint used by this method in your application code.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *rocky* | [Rocky](https://github.com/electricimp/Rocky) instance | Yes | An instance of the [Rocky](https://github.com/electricimp/Rocky) library |
| *deviceModel* | String | Yes | For information, please see [the Amazon documentation](https://developer.amazon.com/docs/dash/lwa-web-api.html#integrate-with-the-lwa-sdk-for-javascript) |
| *deviceSerial* | String | Yes | For information, please see [the Amazon documentation](https://developer.amazon.com/docs/dash/lwa-web-api.html#integrate-with-the-lwa-sdk-for-javascript) |
| *onAuthenticated* | Function | Optional | Callback called when the operation is completed or an error occurs. See below |
| *route* | String | Optional | The login endpoint's route. Default: `"/"` |
| *testDevice* | Boolean | Optional | `true` if it is a test device; `false` by default. For more information, please see [the Amazon documentation](https://developer.amazon.com/docs/dash/test-device-purchases.html) and the [Test Orders](#test-orders) section |
| *nonLiveDevice* | Boolean | Optional | `true` if it is a non-live (pre-production) device; `false` by default. For more information, please see [the Amazon documentation](https://developer.amazon.com/docs/dash/lwa-web-api.html#integrate-with-the-lwa-sdk-for-javascript) (the point about *should_include_non_live* flag) and the [Non-live devices](#non-live-devices) section |

#### onAuthenticated Callback Parameters ####

| Parameter | Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the authentication is successful, otherwise an [error code](#error-code). Possible HTTP error codes [are listed here](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html#access-token-errors) |
| *response* | Table | Key-value table with the response provided by Amazon server. May be `null`. For information on the response format, please see [the Amazon documentation](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html#access-token-response). May also contain error details described [here](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html#access-token-errors) and [here](https://developer.amazon.com/docs/login-with-amazon/authorization-code-grant.html#authorization-errors) |

#### Return Value ####

Nothing. The outcome of the operation may be obtained via the *onAuthenticated* callback, if specified.

#### Example ####

```squirrel
#require "Rocky.class.nut:2.0.1"
#require "AmazonDRS.agent.lib.nut:1.1.0"

const AMAZON_DRS_CLIENT_ID = "<YOUR_AMAZON_CLIENT_ID>";
const AMAZON_DRS_CLIENT_SECRET = "<YOUR_AMAZON_CLIENT_SECRET>";
const AMAZON_DRS_DEVICE_MODEL = "<YOUR_AMAZON_DEVICE_MODEL>";
const AMAZON_DRS_DEVICE_SERIAL = "<YOUR_AMAZON_DEVICE_SERIAL>";

testDevice <- true;
loginRoute <- "/login";

function onAuthenticated(error, response) {
  if (error != 0) {
    server.error("Authentication error: code = " + error + " response = " + http.jsonencode(response));
    return;
  }

  server.log("Successfully authenticated!");
}

client <- AmazonDRS(AMAZON_DRS_CLIENT_ID, AMAZON_DRS_CLIENT_SECRET);
rocky <- Rocky();
client.login(rocky, AMAZON_DRS_DEVICE_MODEL, AMAZON_DRS_DEVICE_SERIAL, onAuthenticated.bindenv(this), loginRoute, testDevice);
```

### setRefreshToken(*refreshToken*) ###

This method allows you to set a Refresh Token manually. For more information, please see the [authentication](#authentication) section. 

Either this method or [*login()*](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice-nonlivedevice) should be called and authentication should be called before making any DRS-related requests.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *refreshToken* | String | Yes | A Refresh Token used to acquire an Access Token and refresh it when it has expired |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
#require "AmazonDRS.agent.lib.nut:1.1.0"

const AMAZON_DRS_CLIENT_ID = "<YOUR_AMAZON_CLIENT_ID>";
const AMAZON_DRS_CLIENT_SECRET = "<YOUR_AMAZON_CLIENT_SECRET>";
const AMAZON_DRS_REFRESH_TOKEN = "<YOUR_AMAZON_VALID_REFRESH_TOKEN>";

client <- AmazonDRS(AMAZON_DRS_CLIENT_ID, AMAZON_DRS_CLIENT_SECRET);
client.setRefreshToken(AMAZON_DRS_REFRESH_TOKEN);
```

### getRefreshToken() ###

The method returns a string with the Refresh Token, or `null` if it has not been set.

#### Return Value ####

String &mdash; The Refresh Token, or `null`.

### replenish(*slotId[, onReplenished]*) ###

This method places an order for a device/slot combination. For more information, please see [the Amazon DRS documentation](https://developer.amazon.com/docs/dash/replenish-endpoint.html).

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *slotId* | String | Yes | The ID of a slot used to place an order |
| *onReplenished* | Function | Optional | Callback function called when the operation is completed or an error occurs |

#### onReplenished Callback Parameters ####

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the replenishment is successful, otherwise an [error code](#error-code). Possible HTTP error codes [are listed here](https://developer.amazon.com/docs/dash/replenish-endpoint.html#error-responses) |
| *response* | Table | Key-value table with the response provided by Amazon server. May be `null`. For information on the response format, please see [the Amazon documentation](https://developer.amazon.com/docs/dash/replenish-endpoint.html#response-example). May also contain error details described [here](https://developer.amazon.com/docs/dash/replenish-endpoint.html#error-responses) |

#### Return Value ####

Nothing. The result of the operation may be obtained via the *onReplenished* callback, if specified.

#### Example ####

```squirrel
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

The method can only be used for the orders made by a [test device](https://developer.amazon.com/docs/dash/test-device-purchases.html). The library does not check if your device authenticated as a test device, so you are responsible for this check. For more information, please see the [Test Orders](#test-orders) section.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *slotId* | String | Optional | The ID of the slot to be canceled. If not specified or `null`, test orders for all slots in the device will be canceled |
| *onCanceled* | Function | Optional | Callback function called when the operation is completed or an error occurs |

#### onCanceled Callback Parameters ####

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the cancelation is successful, otherwise an [error code](#error-code). Possible HTTP error codes [are listed here](https://developer.amazon.com/docs/dash/canceltestorder-endpoint.html#error-responses) |
| *response* | Table | Key-value table with the response provided by Amazon server. May be `null`. For information on the response format, please see [the Amazon documentation](https://developer.amazon.com/docs/dash/canceltestorder-endpoint.html#response-example). May also contain [error details](https://developer.amazon.com/docs/dash/canceltestorder-endpoint.html#error-responses) |

#### Return Value ####

Nothing. The result of the operation may be obtained via the *onCanceled* callback, if specified.

#### Example ####

```squirrel
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

This method enables (*value* is `true`) or disables (*value* is `false`) the library debug output, including error logging. It is disabled by default. 

#### Return Value ####

Nothing.

## Examples ##

Working examples are provided in the [examples](./examples) directory.

The following example shows proper usage of [*login()*](#loginrocky-devicemodel-deviceserial-onauthenticated-route-testdevice-nonlivedevice), [*setRefreshToken()*](#setrefreshtokenrefreshtoken) and [*getRefreshToken()*](#getrefreshtoken) methods. It saves the Refresh Token in server-side persistent storage and then loads it to the library on each agent restart. This saves the user from having to set up their device every time.

```squirrel
#require "Rocky.class.nut:2.0.1"
#require "AmazonDRS.agent.lib.nut:1.1.0"

const AMAZON_DRS_CLIENT_ID = "<YOUR_AMAZON_CLIENT_ID>";
const AMAZON_DRS_CLIENT_SECRET = "<YOUR_AMAZON_CLIENT_SECRET>";
const AMAZON_DRS_DEVICE_MODEL = "<YOUR_AMAZON_DEVICE_MODEL>";
const AMAZON_DRS_DEVICE_SERIAL = "<YOUR_AMAZON_DEVICE_SERIAL>";

function getStoredRefreshToken() {
  local persist = server.load();
  local amazonDRS = {};
  if ("amazonDRS" in persist) amazonDRS = persist.amazonDRS;
  
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

Tests for the library are provided in the [tests](./tests) directory.

## License ##

This library is licensed under the [MIT License](./LICENSE).
