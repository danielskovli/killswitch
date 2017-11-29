// Object/class that deals with storing and retrieving session data
var Session  = {
    
    _name: '',
    _username: '',
    _token: '',
    _fileSystem: '',
    _sessionPath: '',


    // Read from file, create placeholder if file doesn't exist
    read: function() {
        // File exists
        if (Session._fileSystem.existsSync(this._sessionPath)) {
            var content = Session._fileSystem.readTextFromFileSync(Session._sessionPath);
            content = JSON.parse(content);
            Session._name = content.name;
            Session._username = content.username;
            Session._token = content.token;
        
        // File does not exist
        } else {
            Session.write();
        }
    },


    // Write to file
    write: function() {
        var data = {
            name: Session._name,
            username: Session._username,
            token: Session._token
        }
        Session._fileSystem.writeTextToFileSync(Session._sessionPath, JSON.stringify(data))
    },


    // Bulk update for effiency when setting multiple values
    bulkUpdate: function(data) {
        if (data.name && data.username && data.token) {
            Session._name = data.name;
            Session._username = data.username;
            Session._token = data.token;

            Session.write();
            return true;
        
        } else {
            return false;
        }
    },


    // Clear session
    clear: function() {
        Session._name = '';
        Session._username = '';
        Session._token = '';
        Session.write();
    },


    // Getters and setters
    get name() {
        return Session._name;
    },
    set name(n) {
        if (Session._name != n) {
            Session._name = n;
            Session.write();
        }
    },

    get username() {
        return Session._username;
    },
    set username(u) {
        if (Session._username != u) {
            Session._username = u;
            Session.write();
        }
    },

    get token() {
        return Session._token;
    },
    set token(t) {
        if (Session._token != t) {
            Session._token = t;
            Session.write();
        }
    }
}

// Not sure why this can't be run from within the object above, but oh well
Session._fileSystem = require("FuseJS/FileSystem");
Session._sessionPath= Session._fileSystem.dataDirectory + "/" + "session.txt";
Session.read();

// Export
module.exports = Session;