"""
Killswitch listener

This script was written to interface with the Killswitch server, specifically for OSX.
That said, only the KillswitchListener.isLocked() and KillswitchListener.__shutdown() functions
are operating system specific. 

Written for Python 2.7.12 (Ancient, I know)

__shutdown() will most likely work on any Unix based system.
isLocked() is most likely OSX specific, as it relies on the Quartz module.


Daniel Skovli 2017 - daniel.skovli@gmail.com
"""

import os
import time
import urllib2
import socket
import json
import md5
import Quartz #Quarts requires pip install pyobjc-framework-Quartz


URL = "http://apps.danielskovli.com/killswitch/api/1.0/"
CONNECTION_TIMEOUT = 30
LOOP_INTERVAL = 10

# You can store your security token here instead, if you want
USERNAME = "your@email.com"
PASSWORD = md5.new("your password").hexdigest() #Must send your password as an MD5 hash. I can explain, but it's a boring story.


class KillswitchListener(object):

    def __init__(self, url = URL, username = USERNAME, password = PASSWORD, token = None):
        self.url = url
        self.status = None
        self.ready = False
        self.token = token
        self.username = username
        self.password = password
        socket.setdefaulttimeout(CONNECTION_TIMEOUT)

        if token:
            self.ready = True
            print('Using static token {}'.format(self.token))
            return

        try:
            request = urllib2.Request(self.url + "login/")
            request.add_header('Content-Type', 'application/json')
            data = {
                'username': self.username, 
                'password': self.password
            }
            response = urllib2.urlopen(request, json.dumps(data))
            state = json.loads(response.read())
            if state['error'] != False:
                print('Login error: ' + state['error'])
            else:
                print('User {} ({}) logged in successfully'.format(state['name'], state['username']))
                print('Your security token is {} - you can use this directly in your script to skip the login step if you want'.format(state['token']))
                self.token = state['token']
                self.ready = True
        
        except Exception as e:
            print("Couldn't connect to login server. Either server is down, or you've got some Python issues")
            print(e)


    def run(self):
        if not self.ready:
            print("Class didn't initialise properly, and can't run in its current state. Probably a login/token issue")
            return

        # Enter infinite loop. If you don't want to lock up the script, thread this loop and add a better while-check.
        while True:
            if not self.isLocked():
                try:
                    request = urllib2.Request(self.url + "status/" + self.token)
                    response = urllib2.urlopen(request)
                    state = json.loads(response.read())

                    if state['error'] != False:
                        print("Killswitch server returned an error: {}".format(state['error']))
                        return

                    elif state['killswitch'] != self.status:
                        #print "Lock status changed from {} to {}".format(self.status, state['killswitch'])
                        self.status = state['killswitch']
                    
                    if self.status:
                        self.__shutdown()
                    
                    #print("Server returned JSON object: {}".format(state))
                
                except Exception as e:
                    print("Server connection failed. Probably unauthorised usage -- check below")
                    print(e)
                    return
            
            time.sleep(LOOP_INTERVAL)


    def isLocked(self):
        userActive = Quartz.CGSessionCopyCurrentDictionary()
        if userActive and userActive.get("CGSSessionScreenIsLocked", 0) == 0 and userActive.get("kCGSSessionOnConsoleKey", 0) == 1:
            return False
        else:
            return True


    def __shutdown(self, shutdown = False, suspend = False, lock = True):
        # To enable shutdown, add the following to 'visudo' (OSX -> sudo visudo):
        #    %admin  ALL=(ALL) NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown 
        if (shutdown):
            os.system("sudo shutdown -h now")
        elif (suspend):
            os.system("/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend")
        elif (lock):
            os.system("pmset displaysleepnow")
        else:
            # wtf is the user doing?
            pass


listener = KillswitchListener()
#listener = KillswitchListener(token = <your token>)
listener.run()