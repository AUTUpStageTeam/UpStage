#!/usr/bin/python
# -*- coding: utf-8 -*-
# vim: fenc=utf-8 ai ts=4 sts=4 et sw=4

# script to check current installed versions of Python, Twisted and Zope Interfaces

# === check if a supported python version is installed ===

_MIN_PYTHON = (2, 5)    # set this to the minimum required python version
_MAX_PYTHON = (2, 9)    # set this to the maximum python version (excluded)

import sys, string
from distutils.version import LooseVersion #, StrictVersion

py_version = sys.version_info
py_version_string = str(py_version[0]) + "." + str(py_version[1]) + "." + str(py_version[2])
print "=> Installed python version is %s. (2.7 recommended)" % py_version_string
#print sys.version
if not (py_version >= _MIN_PYTHON and py_version < _MAX_PYTHON):
    print "Build requires that python be in version better or equal", \
          '.'.join(['%d'%n for n in _MIN_PYTHON]), \
          "and less than", \
          '.'.join(['%d'%n for n in _MAX_PYTHON]), \
          "installed."
    sys.exit(1)


# === check if a supported twisted version is installed ===

_MIN_TWISTED = '8.1.0'   # set this to the minimum required twisted version (included)
_MAX_TWISTED = '9.0.0'  # set this to the maximum required twisted version (excluded)

try:
    import twisted
except ImportError:
    print "No Twisted installation found!"
    print "Build requires that Twisted be in version better or equal %s and less than %s installed" % (_MIN_TWISTED, _MAX_TWISTED)
    sys.exit(1)

try:
    import twisted.web
except ImportError:
    print "Twisted installation is incomplete. Please additionally install TwistedWeb." 
    sys.exit(1)
 
twisted_version = twisted.__version__

print "=> Installed Twisted version is %s. (8.2.0 recommended)" % twisted_version

if LooseVersion(twisted_version) < LooseVersion(_MIN_TWISTED):
    print "Your twisted version is too old!"

if LooseVersion(twisted_version) > LooseVersion(_MAX_TWISTED):
    print "Your twisted version is too new!"

if not (LooseVersion(twisted_version) >= LooseVersion(_MIN_TWISTED) and LooseVersion(twisted_version) < LooseVersion(_MAX_TWISTED)):
    print "Build requires that twisted be in version better or equal %s and less than %s installed" % (_MIN_TWISTED, _MAX_TWISTED)
    sys.exit(1)

# TODO: additionally check for twisted.woven.guard

# === check if zope.interfaces is installed ===

try:
    import zope.interface
    print "=> found 'zope.interface'."
except ImportError:
    print "Package 'zope.interface' not found. Please install from http://pypi.python.org/pypi/zope.interface"    
    sys.exit(1)

# === all checks passed :) ===

sys.exit(0)
