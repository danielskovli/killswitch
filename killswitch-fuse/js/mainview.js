// The frameworks
var Observable = require("FuseJS/Observable");
var Lifecycle = require('FuseJS/Lifecycle');
var Bundle = require("FuseJS/Bundle");
var Api = require("js/api.js");
var md5 = require("js/md5.js");

// UX bindings
var sessionName = Observable();
var sessionUsername = Observable();
var sessionToken = Observable();
var apiBusy = Observable();
var apiError = Observable();
var apiKillswitch = Observable();
var apiAuthenticated = Observable();
var apiUrls = Observable(Api.urls);
var activeState = Observable("");
var statusOutputText = Observable("");
var signupName = Observable("");
var signupEmail = Observable("");
var signupPassword = Observable("");
var loginEmail = Observable("");
var loginPassword = Observable("");
var appVersion = Observable("-");
var currentYear = Observable((new Date()).getFullYear());
var statusTextDelayedText = "";
var hideStatus = false;

// Load up .unoproj AS JSON
Bundle.read("killswitch.unoproj")
    .then(function(data) {
        var settings = JSON.parse(data);
        appVersion.value = settings.Version;
    }).catch(function(err) {
        appVersion.value = "1.0";
    });

// Subscribe to Lifecycle changes to the app
Lifecycle.on("enteringInteractive", function() {
    if (Api.session.token != '' && activeState.value == 'mainState') {
        refresh();
    }
});

// Subscriber for the API (updating UX binds - couldn't find another way to do this)
Api.subscribers.push(updateBindings);
Api.subscribers.push(navigate);

// Deal with updating UX bindings
function updateBindings() {
    sessionName.value = Api.session.name;
    sessionUsername.value = Api.session.username;
    sessionToken.value = Api.session.token;
    apiBusy.value = Api.busy;
    apiError.value = Api.lastError;
    apiKillswitch.value = Api.killswitch;
    apiAuthenticated.value = Api.authenticated;

    // Status text
    // .busy means we called updateBindings() manually - probably to push out something to the UX
    if (Api.lastError && !Api.busy) { 

        // Special tweak for 'duplicate username'
        if (Api.lastError.toLowerCase().includes('duplicate entry')) {
            Api.lastError = 'This username is already registered';
        }

        setStatusText('Error: ' + Api.lastError);
        //console.log(Api.lastError);
    } else if (!Api.lastError && !Api.busy) {
        setStatusText('');
    }
}

// Deal with (delayed) navigation based on callbacks
function navigate(sender) {
    
    // Callback after Api.addUser() completes
    if (sender == 'addUser') {

        if (Api.lastError) {
            return; // Error display dealt with elsewhere
        }

        // Navigate if required
        if (activeState.value != 'mainState') {
            activeState.value = 'mainState';
        }

        // Reset UX
        signupEmail.value = '';
        signupName.value = '';
        signupPassword.value = '';
        return;
    }

    // Callback after Api.login() completes
    if (sender == 'login') {

        if (Api.lastError) {
            return; // Error display dealt with elsewhere
        }

        // Navigate if required
        if (activeState.value != 'mainState') {
            activeState.value = 'mainState';
        }

        // Reset UX
        loginEmail.value = '';
        loginPassword.value = '';
        return;
    }

    // Callback after Api.update() completes
    if (sender == 'update') {

        if (Api.lastError.toLowerCase().includes('invalid token') || Api.lastError.toLowerCase().includes('authentication error')) {
            activeState.value = 'loginFormState';
            setStatusText('Session expired. Please log in again');
            return;

        } else if (Api.lastError) {
            return; // Error display dealt with elsewhere
        }

        // Navigate if required
        if (activeState.value != 'mainState') {
            activeState.value = 'mainState';
        }
        return;
    }

    // Network error
    if (!Api.busy && Api.lastError == 'Network unreachable') {
        setStatusText(Api.lastError + '. Please try again');

    // Invalid token
    } else if (!Api.busy && Api.lastError == 'Invalid token') {
        activeState.value = 'loginFormState';
        setStatusText('Session expired. Please log in again');

    // Session has expired
    } else if (!Api.authenticated && !Api.busy) {
        activeState.value = 'loginFormState';
        setStatusText('Session expired. Please log in again');
    }
}

// Button based navigation
function changeState(args) {
    ////console.log(args.sender);
    if (args.sender == 'signupButton') {
        activeState.value = 'signupFormState';
    } else if (args.sender == 'loginButton') {
        activeState.value = 'loginFormState';
    } else if (args.sender == 'signupButtonCancel' || args.sender == 'loginButtonCancel') {
        activeState.value = 'loginButtonState';
        setStatusText('');
    }
}

// ChangeState callback (because it won't always take place from a button click)
function changeStateCallback() {
    if (activeState.value == 'signupFormState') {
        setStatusText('Create a Killswitch account');
    } else if (activeState.value == 'loginFormState' && !Api.lastError) {
        setStatusText('Sign in to your Killswitch account');
    } else if (activeState.value == 'loginButtonState' || activeState.value == 'loadingPanel' || activeState.value == 'mainState') {
        //setStatusText('');
    } else if (activeState.value == 'mainState') {
        //refresh();
    }
}

// Sets the status text
function setStatusText(text) {
    statusOutputText.value = text;
}

// Sign up
function signup() {
    var email = signupEmail.value.trim().toLowerCase();
    var name = signupName.value.trim();
    var password = signupPassword.value.trim();

    if (email.length == 0) {
        setStatusText('An email address is required');
        return;
    }
    if (!validateEmail(email)) {
        setStatusText('That\'s not a proper email address...');
        return;   
    }
    if (name.length == 0) {
        setStatusText('You forgot to fill in your name');
        return;
    }
    if (password.length == 0) {
        setStatusText('A password is required');
        return;
    }

    setStatusText('');
    apiBusy.value = true;
    password = md5(password);
    Api.addUser(name, email, password);
}

// Login
function login() {
    var email = loginEmail.value.trim().toLowerCase();
    var password = loginPassword.value.trim();

    if (email.length == 0) {
        setStatusText('An email address is required');
        return;
    }
    if (password.length == 0) {
        setStatusText('A password is required');
        return;
    }

    setStatusText('');
    apiBusy.value = true;
    password = md5(password);
    Api.login(email, password);
}

// The sloppiest email validation ever
function validateEmail(email) {
    var re = /\S+@\S+\.\S+/;
    return re.test(email);
}

// Log out
function logOut() {
    //console.log('trying to log out...');
    Api.session.clear();
    Api.authenticated = false;
    activeState.value = 'loginButtonState';
    updateBindings();
}

// User clicked the killswitch lock icon
function killswitchClick() {
    Api.killswitch = !Api.killswitch;
    updateBindings();
}

// Refresh API and UX
function refresh() {
    Api.update();
    updateBindings();
}

// Check if we have a valid session
if (Api.session.token != '') {
    //console.log('Found token, refreshing data');
    Api.update();
    //updateBindings();
} else {
    //console.log('Need to log in');
    activeState.value = 'loginButtonState';
}

// Lastly, update the bindings
//updateBindings();


// Export UX bindings
module.exports = {
    sessionName: sessionName,
    sessionUsername: sessionUsername,
    sessionToken: sessionToken,
    apiBusy: apiBusy,
    apiError: apiError,
    apiKillswitch: apiKillswitch,
    apiAuthenticated: apiAuthenticated,
    activeState: activeState,
    changeState: changeState,
    statusOutputText: statusOutputText,
    changeStateCallback: changeStateCallback,
    apiUrls: apiUrls,
    logOut: logOut,
    killswitchClick: killswitchClick,
    refresh: refresh,
    signupName: signupName,
    signupEmail: signupEmail,
    signupPassword: signupPassword,
    loginEmail: loginEmail,
    loginPassword: loginPassword,
    appVersion: appVersion,
    signup: signup,
    login: login,
    currentYear: currentYear
};
