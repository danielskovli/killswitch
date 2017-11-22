# Killswitch

A multi-platform app used to remotely shut down or suspend one or many computers (from your phone).


## Getting Started

This system consists of a very simple web API which lets you manage users and their associated killswitch toggle.

### API

The web api both receives and returns JSON objects, and should plug-n-play with just about any http-enabled programming language.

The current version of the api resides at http://apps.danielskovli.com/killswitch/api/1.0/. Some user functionality (like resetting passwords and deleting accounts) can only be accessed from http://apps.danielskovli.com/killswitch/

- **login.php**
```
In: {
  'username': "your@email.com",
  'password': "MD5 hash of your password"
}

Out: {
  'error':      (bool|string) false|error description,
  'token':      (string) security token used for all other api calls,
  'name':       (string) the user's realname, for your pretty gui needs,
  'username':   (string) the user's username,
  'killswitch': (bool) the current killswitch state
}
```

- **getStatus.php**
```
In: {
  'token': "your security token"
}

Out: {
  'error':      (bool|string) false|error description,
  'validToken': (bool) lets you know if the user's token has expired or not,
  'killswitch': (bool) the current killswitch state
}
```

- **addUser.php**
```
In: {
  'username': "your@email.com",
  'password': "MD5 hash of your password",
  'name':     "User's realname"
}

Out: {
  'error': (bool|string) false|error description,
  'token': (string) security token used for all other api calls
}
```
