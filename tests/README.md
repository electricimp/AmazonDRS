# Test Instructions #

The tests in the current directory are intended to check the behavior of the AmazonDRS library.

They are written for and should be used with [impt](https://github.com/electricimp/imp-central-impt). See [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for the details of how to configure and run the tests.

The tests for AmazonDRS library require pre-setup described below.

## Obtain required credentials ##

Firstly, you need to go through [the example's instructions](../examples/README.md#example-setup-and-run) to obtatin required data.

## Set Environment Variables ##

- Set *AMAZON_DRS_CLIENT_ID* environment variable to the value of **Client ID** obtained earlier.\
The value should look like `amzn1.application-oa2-client.d5264d4f0f9141a88dfeXXXXXXXXXXXX`.
- Set *AMAZON_DRS_CLIENT_SECRET* environment variable to the value of **Client Secret** obtained earlier.\
The value should look like `c604cd9aab7b51febc7394ce1fe337693d82dbd03892a3044be7XXXXXXXXXXXX`.
- Set *AMAZON_DRS_REFRESH_TOKEN* environment variable to the value of **Refresh Token** obtained earlier.\
The value should look like `Atzr|IwEBIL8i3Lv0EiId1WgXc2el7...`.
- Set *AMAZON_DRS_SLOT_ID* environment variable to the value of **Slot ID** obtained earlier.\
The value should look like `b4d90248-db3e-4669-bb1c-e7d21bb0c569`.
- For integration with [Travis](https://travis-ci.org) set *EI_LOGIN_KEY* environment variable to the valid impCentral login key.

## Run Tests ##

- See [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for the details of how to configure and run the tests.
- Run [impt](https://github.com/electricimp/imp-central-impt) commands from the root directory of the lib. It contains a default test configuration file which should be updated by *impt* commands for your testing environment (at least the Device Group must be updated).
