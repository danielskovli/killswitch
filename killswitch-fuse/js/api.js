// Load Session interface
var Session = require("js/session.js");

// Killswitch API interface
var Api = {

    // Trackers
    authenticated: false,
    busy: false,
    session: Session,
    lastError: null,
    _killswitch: null,
    subscriber: null,

    // API interface URLs
    urls: {
        login: 'http://apps.danielskovli.com/killswitch/api/1.0/login/',
        user: 'http://apps.danielskovli.com/killswitch/api/1.0/user/',
        status: 'http://apps.danielskovli.com/killswitch/api/1.0/status/',
        changePassword: 'http://apps.danielskovli.com/killswitch/changePassword.php',
        resetPassword: 'http://apps.danielskovli.com/killswitch/resetPassword.php',
        deleteAccount: 'http://apps.danielskovli.com/killswitch/deleteUser.php',
        website: 'http://apps.danielskovli.com/killswitch/',
        download: 'http://apps.danielskovli.com/killswitch/#download'
    },


    // Add new user. Password received as already hashed md5()
    addUser: function(name, username, password) {
        Api.busy = true;
        Api.session.clear();
        fetch(Api.urls.user, {
            method: 'POST', 
            headers: { "Content-type": "application/json"}, 
            body: JSON.stringify({username: username, name: name, password: password})
        }).then(function(response) {
            return Api._handleErrors('addUser', response);
        }).then(function(response) {
            Api.lastError = response.error;
            if (!response.error) {
                Api._killswitch = response.killswitch;
                Api.authenticated = true;
                Api.session.bulkUpdate({
                    name: response.name, 
                    username: response.username, 
                    token: response.token
                });
            }
            Api.busy = false;
            Api._callSubscribers('addUser');
        }).catch(function(response) {
            Api._handleThrows('addUser', response);
        });
    },


    // Authenticate. Password received as already hashed md5()
    login: function(username, password) {
        Api.busy = true;
        Api.session.clear();
        fetch(Api.urls.login, {
            method: 'POST', 
            headers: { "Content-type": "application/json"}, 
            body: JSON.stringify({username: username, password: password})
        }).then(function(response) {
            return Api._handleErrors('login', response);
        }).then(function(response) {
            Api.lastError = response.error;
            if (!response.error){
                Api._killswitch = response.killswitch;
                Api.authenticated = true;
                Api.session.bulkUpdate({
                    name: response.name, 
                    username: response.username, 
                    token: response.token
                });
            }
            Api.busy = false;
            Api._callSubscribers('login');
        }).catch(function(response) {
            Api._handleThrows('login', response);
        });
    },


    // Update killswitch state
    update: function() {
        Api.busy = true;
        fetch(Api.urls.status + Api.session.token)
        .then(function(response) {
            return Api._handleErrors('update', response);
        }).then(function(response) {
            Api.lastError = response.error;
            if (!response.error) {
                Api._killswitch = response.killswitch;
                Api.authenticated = true;
            }
            Api.busy = false;
            Api._callSubscribers('update');
        }).catch(function(response) {
            Api._handleThrows('update', response);
        });
    },


    // Getter and setter for the killswitch state
    set killswitch(state) {
        Api.busy = true;
        fetch(Api.urls.status + Api.session.token + '/' + state, {
            method: 'PUT' 
        }).then(function(response) {
            return Api._handleErrors('killswitch', response);
        }).then(function(response) {
            Api.lastError = response.error;
            if (!response.error) {
                Api._killswitch = response.killswitch;
                Api.authenticated = true;
            }
            Api.busy = false;
            Api._callSubscribers('killswitch');
        }).catch(function(response) {
            Api._handleThrows('killswitch', response);
        });
    },
    get killswitch() {
        return Api._killswitch;
    },


    // Handle HTTP error codes here
    _handleErrors: function(sender, response) {
        // 200: OK
        // 400: Incorrect usage. See `error` for more information
        // 401: Unauthorised (blacklisted or invalid credentials/token)
        // 404: Not found
        // 409: Conflict (User already exists)
        // 500: Server error

        // Check if user has been logged out
        if (response.status == 401) {
            Api.authenticated = false;
        }

        // Only check for 404 and 500 now, as they are the ones that don't return a JSON object
        if (response.status == 404 || response.status == 500) {
            Api.lastError = 'Server error';
            Api.busy = false;
            Api._callSubscribers(sender);
            throw "_handleErrors";
        }

        // Deal with the rest once the promise resolves into a JSON object
        return response.json();
    },


    // Handle network fails here
    _handleThrows: function(sender, error) {

        console.log("_handleThrows error: " + error);
        // Abort if we're being redirected from _handleErrors()
        if (error == "_handleErrors") {
            return;
        }

        // Ignore the actual error for now, it should in general boil down to the same thing
        Api.lastError = 'Network unreachable. Please try again';
        Api.busy = false;
        Api._callSubscribers(sender);
        return;
    },


    // Call subscribers
    _callSubscribers: function(sender) {
        if (typeof Api.subscriber == 'function') {
            Api.subscriber(sender);
        }
    }
}

module.exports = Api;