# Killswitch

A multi-platform app used to remotely shut down or suspend one or many computers (from your phone). The killswitch flag is persistent, which means the daemon will keep activating until the switch has been reset. This is the intended functionality, and means you have some degree of security even if your device password is known to a 3rd party. Depending, of course, on how well you are able to mask the daemon process (and the expertise of your hypothetical intruder). 


## Getting Started

This system consists of a very simple REST API which lets you manage users and their associated killswitch toggle. The apps in this repository already implement the below API calls. So unless you're making your own implementation, just clone and compile whichever one you're in the market for. There's also a Python script in there that can form the base for something quite simple, but very customizable. 

### API

The web API both receives and returns JSON objects, and should plug and play with just about any http-enabled programming language.

The current version of the API resides at http://apps.danielskovli.com/killswitch/api/1.0/.

Some user functionality (resetting passwords, deleting accounts) can only be accessed from the web UI at http://apps.danielskovli.com/killswitch/


- **Add user**
```
URL: http://apps.danielskovli.com/killswitch/api/1.0/user/
Request type: POST

In: {
  'username': (string) your@email.com,
  'password': (string) MD5 hash of your password,
  'name':     (string User's real name
}

Out: {
  'error': (bool|string) false|error description,
  'token': (string) security token used for all other api calls
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

Input: {
  'username': (string) your@email.com,
  'password': (string) MD5 hash of your password
}

Output: {
  'error':      (bool|string) false|error description,
  'token':      (string) security token used for all other api calls,
  'name':       (string) the user's real name, for your pretty gui needs,
  'username':   (string) the user's username,
  'killswitch': (bool) the current killswitch state
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

- **Set status**
```
URL: http://apps.danielskovli.com/killswitch/api/1.0/status/<security token>/<bool>
Request type: PUT

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
