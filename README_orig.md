# Killswitch

A multi-platform app used to remotely shut down or suspend one or many computers (from your phone). The killswitch flag is persistent, which means the daemon will keep activating until the switch has been reset. This is the intended functionality, and means you have some degree of security even if your device password is known to a 3rd party. Depending, of course, on how well you are able to mask the daemon process (and the expertise of your hypothetical intruder).

Project website: http://apps.danielskovli.com/killswitch/


## Getting Started

This system consists of a very simple REST API which lets you manage users and their associated killswitch toggle. The apps in this repository already implement the below API calls. So unless you're making your own implementation, just clone and compile whichever one you're in the market for. There's also a Python script in there that can form the base for something quite simple, but very customizable. 

### API

The web API both receives and returns JSON objects, and should plug and play with just about any http-enabled programming language.

The current version of the API resides at http://apps.danielskovli.com/killswitch/api/1.0/.

Some user functionality (resetting passwords, deleting accounts) can only be accessed from the web UI at the following pages:
- Change password: http://apps.danielskovli.com/killswitch/changePassword.php
- Reset password: http://apps.danielskovli.com/killswitch/resetPassword.php
- Delete account: http://apps.danielskovli.com/killswitch/deleteUser.php

The system keeps a log of recent activity, and will only allow a certain number of unauthorized attempts. The threshold is quite generous, but if you were to receive a 401 reply, please take care to exit the listen-loop and prompt the user to re-authenticate. Security tokens have a long lifespan, so a valid user shouldn't have to worry about this very often, but some care had to be taken to discourage brute force attempts. The same policy applies to all web UI access.


- **Add user**
```
URL: http://apps.danielskovli.com/killswitch/api/1.0/user/
Request type: POST

Payload: {
  'username': (string) your@email.com,
  'password': (string) MD5 hash of your password,
  'name':     (string) User's real name
}

Output: {
  'error':      (bool|string) false|error description,
  'token':      (string) security token used for all other api calls,
  'name':       (string) the user's real name, for your pretty gui needs,
  'username':   (string) the user's username,
  'killswitch': (bool) the current killswitch state (inits as false for new users)
}

HTTP codes:
  200: OK
  400: Incorrect usage. See `error` for more information
  401: Unauthorised (blacklisted)
  409: User already exists
  500: Server error
```

- **Log in**
```
URL: http://apps.danielskovli.com/killswitch/api/1.0/login/
Request type: POST

Payload: {
  'username': (string) your@email.com,
  'password': (string) MD5 hash of your password
}

Output: {
  'error':      (bool|string) false|error description,
  'token':      (string) security token used for all other api calls,
  'name':       (string) the user's real name, for your pretty gui needs,
  'username':   (string) the user's username,
  'killswitch': (bool) the current killswitch state,
  'timestamp':  (int) unix epoch time when the killswitch state was last set (GMT+8)
}

HTTP codes:
  200: OK
  400: Incorrect usage. See `error` for more information
  401: Unauthorised (incorrect username/password, or blacklisted)
  500: Server error
```

- **Get status**
```
URL: http://apps.danielskovli.com/killswitch/api/1.0/status/<security token>
Request type: GET

Payload: None

Out: {
  'error':      (bool|string) false|error description,
  'killswitch': (bool) the current killswitch state,
  'timestamp':  (int) unix epoch time when the killswitch state was last set (GMT+8)
}

HTTP codes:
  200: OK
  400: Incorrect usage. See `error` for more information
  401: Unauthorised (invalid token, or blacklisted)
  500: Server error
```

- **Set status**
```
URL: http://apps.danielskovli.com/killswitch/api/1.0/status/<security token>/<bool>
Request type: PUT

Payload: None

Out: {
  'error':      (bool|string) false|error description,
  'killswitch': (bool) the current killswitch state
}

HTTP codes:
  200: OK
  400: Incorrect usage. See `error` for more information
  401: Unauthorised (invalid token, or blacklisted)
  500: Server error
```
