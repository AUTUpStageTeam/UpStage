#!/usr/bin/python
#Copyright (C) 2003-2006 Douglas Bagnall (douglas * paradise-net-nz)
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
"""
If executed as a script, the upstage.config module is imported and
updated according to commandline arguments.

Then, normally, the script will daemonised, and start up an upstage
server.

Use  --help on the commandline to see other options.
"""

import os, sys

from upstage import config
from upstage.policyfileserver import policy_server

#twisted
from twisted.python import usage, log

class Options(usage.Options):
    """
    Instances parse commandline options, and appear to python as a
    dictionary-like thing.
    """
    optParameters = [["swfport", "p", config.SWF_PORT, "Port to use"],
                     ["webport", "w", config.WEB_PORT, "web server's port"],
                     ["policyport", "o", config.POLICY_FILE_PORT,
                        "policy file server's port"],
                     ["logfile", "l", config.LOG_FILE, "where to log"],
                     ["pidfile", "P", config.PID_FILE, "process id file"],
                     ["basedir", "b", config.BASE_DIR,
                        "directory from which to find files"]]

    optFlags = [["no-daemon", "n", "do not daemonise."],
                ["kill", "k", "kill the process in PIDFILE"]]

def daemonise(pidfile, errlog, outlog=None):
    if os.path.exists(pidfile):
        print "WARNING: PID file exists"
    sys.stdout.flush()
    sys.stderr.flush()
    if os.fork():   # launch child and...
        os._exit(0) # kill off parent
    os.setsid()
    if os.fork():   # launch child and...
        os._exit(0) # kill off parent again.
    os.umask(0033)
    # print 'creating daemon'
    try:
        err = open(errlog, 'a+', 0)
        if outlog:
            out = open(outlog, 'a+', 0)
        else:
            out = err
        os.dup2(out.fileno(), sys.stdout.fileno())
        os.dup2(err.fileno(), sys.stderr.fileno())
        os.close(sys.__stdin__.fileno())

    except IOError:
        #not much to usefully do, except print all over the console
        #and hope someone notices
        sys.stderr = sys.__stderr__
        sys.stdout = sys.__stdout__
        print 'Epic fail line 64'
        #print_exc()

    pid = os.getpid()
    print str(pid) #hmm does not even get here...
    f = open(pidfile, 'w')
    f.write(str(pid))
    f.close()

def port_int(s):
    n = int(s)
    if n < 1024 or n > 65234:
        raise ValueError("%s is out of range for a port number" % n)
    return n


def main():
    """poke any command line options into upstage.config before
    importing and calling the upstage modules"""
    options = Options()
    try:
        options.parseOptions()
        config.WEB_PORT = port_int(options["webport"])
        config.SWF_PORT = port_int(options["swfport"])
        config.POLICY_FILE_PORT = port_int(options["policyport"])
        config.LOG_FILE = options["logfile"]
        config.BASE_DIR = options["basedir"]
        config.PID_FILE = options["pidfile"]

    except usage.UsageError, e:
        print "Sorry, I don't understand: %s\n\n %s" % (e, options)
        sys.exit()
    except ValueError, e:
        print "\nERROR: ports have to be integers between 1024 and 65354\n\n%s" % options
        sys.exit()

    if options['kill']:
        try:
            f = open(config.PID_FILE)
            pid = int(f.read())
            f.close()
        except IOError,e:
            print "%s\ncan't read PID file." %(e)
            pid = None
        try:
            os.kill(pid, 15)
        except (IOError, TypeError, OSError), e:
            print "%s\n\ncan't kill process %s, continuing anyway." %(e, pid)
        sys.exit()
        
    if not options['no-daemon']:
        daemonise(config.PID_FILE, config.LOG_FILE)


    #change into base dir so all the relative paths work. XXX better to fix the paths?
    os.chdir(config.BASE_DIR)
    
    #don't start logging before sys.stderr is pointed to logfile.
    #XXX should use twisted.python.logfile to get rotation.
    log.startLogging(sys.stderr)


    ############ Policy File Server - Startup ############
	
    pid = os.fork()
    if pid == 0:
    	try:
            # Starts the server for serving policy files (for latest version of flash player)
            policy_server(config.POLICY_FILE_PORT, config.POLICY_FILE).run()
        except Exception, e:
            log.msg('Error Policy FILE SERVER!')
            print >> sys.stderr, e
            sys.exit(1)
        sys.exit()

    ############ Policy File Server - Startup ############
   

    #don't import the upstage modules until config is settled.
    from upstage.app import do_it

    try:
        do_it()
    finally:
        if not options['no-daemon']:
            os.remove(config.PID_FILE)
        #XXX add calls to save state?

if __name__ == '__main__':
    main()
