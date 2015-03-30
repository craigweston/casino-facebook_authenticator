# casino-facebook_authenticator
[![Build Status](https://travis-ci.org/craigweston/casino-facebook_authenticator.svg?branch=master)](https://travis-ci.org/craigweston/casino-facebook_authenticator)
[![Coverage Status](https://coveralls.io/repos/craigweston/casino-facebook_authenticator/badge.svg)](https://coveralls.io/r/craigweston/casino-facebook_authenticator)

*This project is currently under development*

Provides mechanism to use Facebook as an authenticator for [CASino](https://github.com/rbCAS/CASino).

This authenticator uses the Facebook JavaScript SDK to log in users via a login button on the CASino login page. After logging in and generating an access token on the client side, the token is passed to the server where it is verified against Facebook and then mapped against an existing user in the database using Active Record.

This project uses external authenticator mechanism to integrate third party login providers into CASino. This functionality is not part of the CASino core and is only available through a fork of CASino located [here](https://github.com/craigweston/CASino).

The idea for this originally came from [Issue #32](https://github.com/rbCAS/CASino/issues/32) of CASino.

##Configuration

As mentioned above, this authenticator does not integrate with the standard *authenticators* configuration section of CASino. Instead a new section is required called *external_authenticators* within the *cas.yml*.

You must provide a Facebook app ID and app secret, as well as connection information for your datastore.

```
  external_authenticators:
    facebook:
      authenticator: "Facebook"
      options:
        connection:
          adapter: "mysql2"
          host: "localhost"
          username: "username"
          password: "password"
          database: "CASinoApp"
        app_id: "1111111111111111"
        app_secret: "11111111111111111111111111111111"
        ...

```

###Datastore Configuration

To support multiple datastore layouts, the casino-facebook_authenticator allows table and column names to be configured within the authenticator options.

Below outlines the different configuration types.

####Single user table

This configuration uses only one table to store both the user and the facebook_id. The facebook_id column is used to lookup the user by the Facebook id.

```
  external_authenticators:
    facebook:
      authenticator: "Facebook"
      options:
        ...
        user_table: "users"
        username_column: "username"
        facebook_id_column: "facebook_id"
        ...
```

####User table with mapping table

This configuration allows the Facebook id to be stored in a seperate table and mapped back to the user table with a user id column. This table should be setup with the bare minimum of a user_id column and facebook_id column.

```
  external_authenticators:
    facebook:
      authenticator: "Facebook"
      options:
        ...
        user_table: "users"
        username_column: "username"
        facebook_id_column: "facebook_id"
        account_table: 'accounts'
        account_user_id_column: 'user_id'
        ...
```

####User table with mapping table with account type
This configuration allows multiple account types to be stored in one table, with the specific type of account stored in the account_type_column. This allows multiple third party accounts to be stored in one table. 

By default the account type for this authenticator is *facebook*, however this can be overriden by providing an account_type value in the configuration.

```
  external_authenticators:
    facebook:
      authenticator: "Facebook"
      options:
        ...
        user_table: 'users'
        username_column: 'username'
        facebook_id_column: 'account_id'
        account_table: 'accounts'
        account_user_id_column: 'user_id'
        account_type_column: 'account_type'
        account_type: 'facebook' # [optional]
        ...
```


## License

casino-facebook_authenticator is released under the [MIT License](http://www.opensource.org/licenses/MIT). See LICENSE.txt for further details.
