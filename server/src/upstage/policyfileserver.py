#!/usr/bin/env python
#
# flashpolicyd.py
# Simple socket policy file server for Flash
#
# Usage: flashpolicyd.py [--port=N] --file=FILE
#
# Logs to stderr
# Requires Python 2.5 or later

#from __future__ import with_statement

import sys
import optparse
import socket
import thread
import exceptions
#import contextlib

#twisted
from twisted.python import log


class policy_server(object):
    def __init__(self, port, policy):
        self.port = port
        self.policy = policy
        if len(policy) > 10000:
            raise exceptions.RuntimeError('File probably too large to be a policy file')
        if 'cross-domain-policy' not in policy:
            raise exceptions.RuntimeError('Not a valid policy file')

        log.msg('Listening on port %d' % port)
        
        #try:
        #    self.sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
        #except AttributeError:
        #    # AttributeError catches Python built without IPv6
        #    self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        #except socket.error:
        #    # socket.error catches OS with IPv6 disabled
        #    self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
        # FIXME currently start with ipv4 only (ipv6 seems not working in windows)
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(('', port))
        self.sock.listen(5)

    def run(self):
        try:
            while True:
                thread.start_new_thread(self.handle, self.sock.accept())
        except socket.error, e:
            log.msg('Error accepting connection: %s' % (e[1],))

    def handle(self, conn, addr):
        addrstr = '%s:%s' % (addr[0],addr[1])
        try:
            log.msg('Connection from %s' % (addrstr,))
            #contextlib.closing(conn)
            # It's possible that we won't get the entire request in
            # a single recv, but very unlikely.
            request = conn.recv(1024).strip()
            if request != '<policy-file-request/>\0':
                log.msg('Unrecognized request from %s: %s' % (addrstr, request))
                return
            log.msg('Valid request received from %s' % (addrstr,))
            conn.sendall(self.policy)
            log.msg('Sent policy file to %s' % (addrstr,))
        except socket.error, e:
            log.msg('Error handling connection from %s: %s' % (addrstr, e[1]))
        except Exception, e:
            log.msg('Error handling connection from %s: %s' % (addrstr, e[1]))
