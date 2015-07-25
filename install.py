#!/usr/bin/env python
#-*- coding:utf-8 -*-
"""
A python program to compile UpStage ActionScript Client and prepare the server deployment methods later on.
"""

import os, sys
appCanonicalPath = os.getcwd()
appServerDir = appCanonicalPath + '/server/src'
appClientDir = appCanonicalPath + '/client/src'
buildDir = './build'
outDir = './dist'

"""
Compiles the Actionscript classes into swf file.
"""
def compile_client():
    print "Start compiling UpStage Client..."
    temp = appCanonicalPath + '/client/src/temp'
    print "Create temp folder..."
    os.system('mkdir ' + temp)
    mtasc = 'mtasc -swf ' + temp + '/classes.swf -frame 1 -header 320:200:31 -trace App.debug -version 8 -v -strict -msvc -wimp -cp ' + appClientDir + '/ App.as upstage/Client.as'
    print "Prepare mtasc command:"
    print mtasc
    os.system(mtasc)
    print "Copy font and image resources from client directory to a temp directory..."
    os.system('cp -r '+ appClientDir + '/font/*.ttf ' + temp)
    os.system('cp -r '+ appClientDir + '/image/*.png ' + temp)
    swfmill = 'swfmill -v simple ' + appClientDir + '/application.xml ' + appServerDir +'/html/swf/client.swf'
    print "swfmill compiles AS client to a swf file for server to send stage instance..."
    print "Prepare swfmill command:"
    print swfmill
    os.system(swfmill)
    print "UpStage compilation process is completed. Please be aware of any compile-error in the above lines."

"""
Cleans up etc.
"""
def finalizeSetup():
    print '''\n***************************************************************
    \n*Thank you for choosing UpStage!, please visit upstage.org.nz *
    \n*for more information about UpStage.                          *
    \n***************************************************************
    \n*Now please enter "dist" directory to use UpStage server      *
    \n*utilities                                                    *
    \n***************************************************************
    \n*To demonize a new server: upstage-server shall deploy server *
    \n*with a predined setting.                                     *
    \n*To Start a server : upstage-admin start servername           *
    \n*To list active instances: upstage-admin ls                   *
    \n*			        		 AUT UpStage Team   *
    \n***************************************************************'''

"""
Execute the script.
"""
if(len(sys.argv) >= 2):
    if(sys.argv[1] == 'cc'):
        compile_client()
else:
    print "Consutruct build and out directories"
    os.system('mkdir ' + buildDir)
    os.system('mkdir ' + outDir)
    os.system('cp -r ./server/src/* ' + outDir + '/')
    os.system('cp -r ./client/* ' + buildDir + '/')
    print "Compile resources with mtasc"
    os.system('mtasc -swf simple ' + buildDir + '/src/temp/classes.swf -frame 1 -header 320:200:31 -version 8 -v -strict -msvc -wimp -cp ' + buildDir + '/src/' + buildDir +'/src/App.as')
    print "Compile resources with swfmill"
    os.system('swfmill -v simple ' + buildDir + '/src/application.xml ' + buildDir + '/client.swf')
    print "Move compiled client to the predefined canonical directory: " + outDir
    os.system('mv ' + buildDir + '/client.swf ' + outDir + '/html/client.swf')
    print "Remove the temp build directory"
    os.system('rm -rf ' + buildDir)
    finalizeSetup()
