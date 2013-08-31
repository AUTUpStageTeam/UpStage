#!/usr/bin/python

"""
This script is used to stop and start upstage server instances.

upstage-admin stop  [server-name]
upstage-admin start [server-name]
upstage-admin restart [server-name]

upstage-admin create [server-name]
  create a new server.

upstage-admin ls
upstage-admin list
  list the configured servers (and indicate whether they are running)

upstage-admin rm [server-name]
upstage-admin remove [server-name]
  delete a server's configuration

"""

import os, sys, shutil, termios, subprocess
from cStringIO import StringIO
from ConfigParser import SafeConfigParser, NoOptionError
from md5 import md5

from upstage.config import HTDOCS, ADMIN_DIR, TEMPLATE_DIR, \
     CONFIG_DIR, PLAYERS_XML, SWF_DIR, POLICY_FILE_PORT

#helper functions for input.

def word(msg, default=''):
    """restricts to alphanumeric"""
    while True:
        a = raw_input("%s [%s]" %(msg, default)).lower() or default
        if a.isalnum():
            return a
        print "no spaces or funny characters, sorry"

def password(msg1, msg2='again:', msg3="that didn't match"):
    """does not echo, asks twice"""
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    new = termios.tcgetattr(fd)
    new[3] = new[3] & ~termios.ECHO   # magic term flags
    try:
        termios.tcsetattr(fd, termios.TCSADRAIN, new)
        while True:
            p1 = raw_input(msg1)
            p2 = raw_input('\n' + msg2)
            if p1 == p2:
                break
            print '\n' + msg3
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    return p1


def yesno(msg, default='y/n'):
    """yes/y => True, no/n => False"""
    while True:
        a = raw_input("%s [%s]" %(msg, default)).lower() or default
        if a in ('y', 'yes', 'n', 'no'):
            return a in ('y', 'yes')
        print "yes or no?"


def port_no(msg, default=''):
    while True:
        a = raw_input("%s [%s]" %(msg, default)).lower() or default
        if a.isdigit() and int(a) > 1024 and int(a) < 65354:
            return int(a)
        print "pick a number between 1024 and 65354"


def filepath(msg, default='', type='file'):
    while True:
        a = raw_input("%s [%s]" %(msg, default)) or default
        a = os.path.abspath(a)
        if os.path.exists(a):
            if type == 'file' and not os.path.isfile(a):
                print "not a proper file!"
                continue
            elif type == 'dir' and not os.path.isdir(a):
                print "not a directory!"
                continue
            elif type == 'dir' and not yesno("directory exists -- reuse it?"):
                continue
                
        d, f = os.path.split(a)
        if not os.path.isdir(d):
            try:
                os.makedirs(d, 0755)
            except IOError, e:
                print e
                continue
        return a



#####################################

class Conf(SafeConfigParser):
    def __init__(self, filename):
        SafeConfigParser.__init__(self)
        self.filename = filename
        self.read(filename)


    def find_next_ports(self):
        """Finds likely port numbers to offer as defaults."""
        wp, sp = 8080, 7229
        for section in self.sections():
            if self.has_option(section, 'webport') and self.has_option(section, 'webport'):
                wp = max(wp, self.getint(section, 'webport'))
                sp = max(sp, self.getint(section, 'swfport'))
        return (wp + 1, sp + 1)

    def save(self):
        #re-write the conf file
        f = open(self.filename, 'w')
        self.write(f)
        f.close()
        

    def start(self, name):
        webport = self.get(name, 'webport')
        swfport = self.get(name, 'swfport')
        policyport = self.get(name, 'policyport')
        logfile = self.get(name, 'logfile')
        pidfile = self.get(name, 'pidfile')
        basedir = self.get(name, 'basedir')
     
        cmd = 'upstage-server -p %s -w %s -o %s -l %s -P %s -b %s' \
              %(swfport, webport, policyport, logfile, pidfile, basedir)
        print cmd
        err = os.system(cmd)
        if err:
            print "an error occured (%s)" % err


    def stop(self, name):
        pidfile = self.get(name, 'pidfile')
        try:
            f = open(pidfile)
            pid = int(f.read())
            f.close()
            os.kill(pid, 15)
            #os.remove(pidfile) #upstage-server does this itself
        except (IOError, OSError), e:
            print "couldn't find process to kill -is it running?", e

    def cmd_create(self, name=None):
        """Set up a new server"""
        print "Setting up a new server"
        wp, sp = [str(x) for x in self.find_next_ports()]

        while name is None or name == 'DEFAULT' or name in self.sections():
            if  name is not None:
                print "sorry, the name '%s' is taken or reserved" % name
            name = word("What name should the server have?", wp)

        webport = port_no("Which port should the web server listen on? (1024-65534)", wp or '')
        swfport = port_no("Which port should the flash sockets use? (1024-65534)", sp or '')
       
        # AC - Added to allow the selection of the policy file server port
        policyport = port_no("Which port should policy files be served over? (1024-65534)", str(POLICY_FILE_PORT) or '')

        lf = os.path.abspath("%s/upstage-%s.log" % (self.get('DEFAULT', 'log_dir'), name))
        logfile = filepath("Where should the logs go? [%s]" % lf, lf)

        bd = os.path.abspath("%s/%s" % (self.get('DEFAULT', 'data_dir'), name))
        basedir = filepath("Where should the server's data go? [%s]" % bd, bd, type='dir')

        pf = os.path.abspath("%s/upstage-%s.pid" % (self.get('DEFAULT', 'pid_dir'), name))
        pidfile = filepath("Where should the process identifier (PID) file go? [%s] (just press enter)" % pf, pf)
		
        for p in (logfile, pidfile, basedir + '/xx'):
            d, f = os.path.split(p)
            if not os.path.isdir(d):
                print "making directory %s" % d
                os.makedirs(d, 0755)

        self.add_section(name)
        self.set(name, 'webport', str(webport))
        self.set(name, 'swfport', str(swfport))
        self.set(name, 'policyport', str(policyport))
        self.set(name, 'logfile', logfile)
        self.set(name, 'pidfile', pidfile)
        self.set(name, 'basedir', basedir)

        if not os.listdir(basedir) or yesno("The server's data directory already exists.\n "
                                            "Should this data be replaced?"):
            default_data = self.get('DEFAULT', 'default_data')
            for x in (HTDOCS, CONFIG_DIR):
                dest = os.path.join(basedir, x)
                src = os.path.join(default_data, x)
                if os.path.exists(dest):
                    os.system('rm -r %s' % dest)
                shutil.copytree(src, dest)

            self.set_admin(name)

        self.save()

        print "NOTE: these files and directories need to be writeable by the user that will be running the server:"
        for x in (logfile, pidfile, basedir):
            print x
        ##print "you might want to chown -R them" #PQ: Old: Before it didnt't chown the folders for you
        #PQ: Added 5/8/07
        print "Let me chown the UpStage folders for you!"
        #PQ: Chown the upstage folders
        os.system("chownme.sh")


    def set_admin(self, name):
        print "You'll need to set up an admin user for this server (you can add more later)"
        user = word("what is the admin's username?")
        pw = password("enter the admin password", "the same password again")
        #XXX should be using upstage libraries for this
        xml = '<players><player password="%s" name="%s" rights="act,admin,su" date="forever" email="notset" /></players>'
        xmlpath = os.path.join(self.get(name, 'basedir'), PLAYERS_XML)
        f = open(xmlpath, 'w')
        f.write(xml %(md5(pw).hexdigest(), user))
        f.close()

    def cmd_rm(self, name=None):
        """Remove a server from the list"""
        if name is None:
            print "no server specified"
        elif name in self.sections() and \
                 yesno("delete configuration for the server '%s'? this is irreversible.", 'n'):
            if yesno("should I try to stop the server (is it running?)"):
                self.stop(name)
            basedir = self.get(name, 'basedir')
            self.remove_section(name)
            print "data remains in the directory '%s'" % basedir
            self.save()

    def cmd_start(self, name=None):
        """Start a server"""
        servers = self.sections()
        if name in servers:
            self.start(name)
        elif name is None and len(servers) > 1:
            print "don't know which server to start"
        elif name is None and len(servers) == 1:
            self.start(servers[0])
        elif yesno('Do you want to set up a server? (y/n)'):
            self.cmd_create(name)


    def cmd_stop(self, name=None):
        """Stop a running server"""
        servers = self.sections()
        if name in servers:
            self.stop(name)
        elif name is None and len(servers) > 1:
            print "don't know which server to stop"
        elif name is None and len(servers) == 1:
            self.stop(servers[0])
        else:
            print "no upstage servers appear to be configured"


    def cmd_restart(self, name=None):
        """Stops and starts the server"""
        servers = self.sections()
        if name in servers:
            self.stop(name)
            self.start(name)
        elif name is None and len(servers) > 1:
            print "don't know which server to restart"
        elif name is None and len(servers) == 1:
            self.stop(servers[0])
            self.start(servers[0])
        else:
            print "no upstage servers appear to be configured"


    def cmd_ls(self):
        """list running servers"""
        for name in self.sections():
            pidfile = self.get(name, 'pidfile')            
            try:
                f = open(pidfile)
                pid = int(f.read())
                f.close()
            except IOError:
                print name
                continue
            s = os.popen4('kill -0 %s' %pid, 'r')[1].read()
            #patched for python 2.6
            #s = subprocess.Popen('kill -0 ' + str(pid), shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, close_fds=True)
            if s:
                print '%-18s stopped?' % name
            else:
                print '%-18s running' %name
                

    def cmd_reset(self, name=None):
        """Reset a servers templates or configuration files"""
        servers = self.sections()
        if name is None:
            if len(servers) != 1:
                name = servers[0]
            else:
                name = word("reset which server? %s" % servers)

        opj = os.path.join
        
        if name in servers:
            self.stop(name)
            defaults = self.get('DEFAULT', 'default_data')
            basedir =  self.get(name, 'basedir')
            for question, d, exc in (("reset the html templates?", TEMPLATE_DIR, []),
                                     ("reset the admin html?", ADMIN_DIR, []),
                                     ("reset backdrops, props and avatars?", CONFIG_DIR,
                                      ['stages', 'templates', 'players.xml', 'stages.xml']),
                                     ("reset swf files?", SWF_DIR, []),
                                     ):
                if yesno(question):
                    src = opj(defaults, d)
                    dest = opj(basedir, d)
                    for fn in os.listdir(src):
                        if fn not in exc:
                            shutil.copy(opj(src, fn), opj(dest, fn))
                
                            
            self.start(name)
        else:
            print "unknown server, doing nothing"


    cmd_list = cmd_ls
    cmd_delete = cmd_rm
    cmd_remove = cmd_rm

if __name__ == '__main__':
    if len(sys.argv) < 2 or '--help' in sys.argv:
        print __doc__
        print "Commands:"
        cmdl = [ (v.__doc__, k[4:]) for k, v in Conf.__dict__.items() if k.startswith('cmd_') ]
        cmdd = {}
        for doc, cmd in cmdl:
            cmdd[doc] = cmdd.get(doc, [])
            cmdd[doc].append(cmd)
        for doc, cmds in cmdd.items():
            print "\n %s\n       %s" %('\n '.join(cmds), doc)                                    
        sys.exit()

    conf = Conf('/usr/local/etc/upstage/upstage-admin.conf')
    fn = 'cmd_' + sys.argv[1]
    if hasattr(conf, fn):
        getattr(conf,fn)(*sys.argv[2:])
