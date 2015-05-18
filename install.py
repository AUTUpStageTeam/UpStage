#!/usr/bin/env python
#-*- coding:utf-8 -*-
"""
# A very simple script used to install upstage to the appropriate
# directories. Ensure that the Server folder is present.
# Usage: copy install.py to the directory containing Server folder
# execute using python install.py
# ensure you are root!
# To generate a deb file simply type: python install.py deb
# or if you want to give your package another name: python install.py deb packagename
# @author: Heath Behrens (AUT UpStage Team)
# Changelog: Created on 09-April-2011
# Modified: 11/04/2011 - Added function to parse_control_file so deb can now be generated
# without the user naming the package
# -Added compiling of the client, generates the flex-config file (needs some work though)
# -Fixed silly bug with permissions. Added more descriptive comments to the functions.
# -Added removal of .svn directories which do not play nicely with the script for now. Also added changing of permissions for deb files.
# -Completed the compiling of the client which now works. Usage is: python install.py cc /path/to/flex
#
# Modified by Nitkalya Wiriyanuparb: 22/10/2013 - Used mtasc and swfmill instead of flex, adjusted folder structure, change svn to git
"""

import os
import sys
from distutils import dir_util
from distutils import file_util
import shutil
import tarfile
import fileinput

baseDir = '/usr/local/share/'
serverDir = '/usr/local/'
config_path = '/usr/local/etc/'
backup_location = '/etc/cron.weekly/'
appRootDir = os.path.abspath('.').replace(" ", "\ ")
appServerDir = os.path.abspath('./server/src').replace(" ", "\ ")
appClientDir = os.path.abspath('./client').replace(" ", "\ ")
control_file_location = appRootDir+'/DEBIAN/control'
system_calls = ['chmod +x /usr/local/upstage/*', 'chmod +x /etc/cron.weekly/upstage-backup', 'ln -s /usr/local/upstage/* /usr/local/bin/', 'ln -s /etc/cron.weekly/upstage-backup /usr/local/bin/']
server_files = ['chownme.sh','img2swf.py','speaker.py','upstage-admin','upstage-admin.conf','upstage-backup','upstage-server']

"""
Replaces a line of text with another line of text in a file. Just a simple helper method.
"""
def replaceAll(file,searchExp,replaceExp):
	for line in fileinput.input(file, inplace=1):
		if searchExp in line:
			line = line.replace(searchExp,replaceExp)
		sys.stdout.write(line)

"""
Compiles the client, Actionscript 3 into swf file. The path to the compiler must be
provided.
"""
def compile_client(): #compiler_path):
	print "Compiling Client..."
	temp = appRootDir + '/temp'
	os.system('mkdir ' + temp)

	# using mtasc and swfmill - hard code options for now
	mtasc = 'mtasc -swf ' + temp + '/classes.swf -frame 1 -header 320:200:31 -trace App.debug -version 8 -v -strict -msvc -wimp -cp ' + appClientDir + '/src App.as upstage/Client.as'
	print mtasc
	os.system(mtasc)

	os.system('cp -r '+ appClientDir + '/src/font/*.ttf ' + temp)
	os.system('cp -r '+ appClientDir + '/src/image/*.png ' + temp)

	swfmill = 'swfmill -v simple ' + appClientDir + '/src/application.xml ' + appServerDir +'/html/swf/client.swf'
	print swfmill
	os.system(swfmill)

	os.system('rm -rf ' + temp)

	# using flex - don't know if it still works

	# current_path = os.path.abspath('')
	# os.system('cp '+current_path+'/client/upstage/org/flex-config.xml '+current_path+'/')
	# flex_config_path = current_path + '/flex-config.xml'
	# print flex_config_path
	# #replace expression
	# replaceAll(flex_config_path,'<source-path></source-path>','\t<source-path><path-element>'+current_path+'/client/upstage/'+'</path-element></source-path>\n')
	# os.system('cp '+flex_config_path +' '+ compiler_path+'/frameworks/')
	# os.system(compiler_path+'/bin/mxmlc' +' '+current_path+'/client/upstage/org/main.mxml')
	# file_util.copy_file(current_path+'/client/upstage/org/main.swf', current_path+'/html/swf/classes.swf')

"""
Parses the control file to extract the user
"""
def parse_control_file():
    version = ''
    name = ''
    if(os.path.exists(control_file_location)):
        print control_file_location
        f = open(control_file_location, 'r')
        for line in f:
            if('Version' in line):
                version = line.split(':')[1].strip()
                print version
            if('Package' in line):
                name = line.split(':')[1].strip();
    return name+'-'+version

"""
Generates a deb file from the source code. The package name
can be ommitted. In which case it uses the name and version number
in the control file.
"""
def generate_deb(packagename):
    if(not len(packagename)>0):
        packagename = parse_control_file()
        print packagename
    os.system('rm -rf `find . -type d -name .git`')
    rootpath = appRootDir+'/'+packagename;
    os.makedirs(rootpath) #create root direction
    #copy the directory tree to the root of the destination
    dir_util.copy_tree(appServerDir+'/html', rootpath+baseDir+'upstage/DEFAULT/html/')
    dir_util.copy_tree(appServerDir+'/config', rootpath+baseDir+'upstage/DEFAULT/config/')
    dir_util.copy_tree(appServerDir+'/upstage', rootpath+serverDir+'upstage/upstage/')
    dir_util.copy_tree(appRootDir+'/DEBIAN', rootpath+'/DEBIAN')
    for file in server_files:
        if(file == 'upstage-admin.conf'):
            if(not os.path.exists(rootpath+config_path+'upstage/')):
                print 'Creating: '+rootpath+config_path+'upstage/'
                os.makedirs(rootpath+config_path)
                os.makedirs(rootpath+config_path+'upstage/')
            file_util.copy_file(appServerDir+'/'+file, rootpath+config_path+'upstage/'+file)
            print 'Copied: '+appServerDir+'/'+file+ ' -to- '+ rootpath+config_path+'upstage/'+file
        if(file == 'upstage-backup'):
            os.makedirs(rootpath+'/etc')
            os.makedirs(rootpath+'/etc/cron.weekly')
            file_util.copy_file(appServerDir+'/'+file, rootpath+backup_location+file)
            print 'copied: '+ appServerDir+'/'+file+' -to- '+ rootpath+backup_location+file
        shutil.copyfile(appServerDir+'/'+file, rootpath+serverDir+'upstage/'+file)
        print 'copied: '+ appServerDir+'/'+file+' -to- '+ rootpath+serverDir+'upstage/'
    os.system('dpkg -b '+packagename) #create the deb package
    os.system('rm -r '+packagename) #cleanup

"""
Cleans up etc.
"""
def finalizeSetup():
	print '\n'
	print 'Finalizing Setup.'
	print '\n'
	for call in system_calls:
		os.system(call)
	print '***************************************************************'
	print '\n'
	print 'Thank you for choosing to use UpStage!'
	print 'Visit upstage.org.nz for more information about UpStage'
	print '\n'
	print '***************************************************************'
	print '\n'
	print 'To Create a new server run as root: upstage-admin create'
	print 'To Start a server run as root: upstage-admin start servername'
	print 'To See if any servers are active run as root: upstage-admin ls\n'
	print '												  AUT UpStage Team'
	print '\n'
	print '***************************************************************'

"""
Copies files and folders to the installed paths
"""
def copyFiles(location, noargs):
	if(noargs):
		if(os.path.exists(location+'/config')):
			dir_util.copy_tree(location+'/config', baseDir+'upstage/DEFAULT/config/')
			print 'Copying Directory: '+location+'/config' + ' -to- '+ baseDir+'upstage/DEFAULT/config/'
		if(os.path.exists(location+'/html')):
			dir_util.copy_tree(location+'/html', baseDir+'upstage/DEFAULT/html/')
			print 'Copying Directory: '+location+'/html' + ' -to- '+ baseDir+'upstage/DEFAULT/html/'
		if(os.path.exists(location+'/upstage'))	:
			dir_util.copy_tree(location+'/upstage', serverDir+'upstage/upstage/')
			print 'Copying Directory: '+location+'/upstage' + ' -to- '+ serverDir+'upstage/upstage/'
		for file in server_files:
			if(file == 'upstage-admin.conf'):
				if(not os.path.exists(config_path+'upstage/')):
					print 'Creating: '+config_path+'upstage/'
					os.makedirs(config_path+'upstage/')
				file_util.copy_file(location+'/'+file, config_path+'upstage/'+file)
				print 'Copied: '+location+'/'+file+ ' -to- '+ config_path+'upstage/'+file
			if(file == 'upstage-backup'):
				file_util.copy_file(location+'/'+file, backup_location+file)
				print 'copied: '+ location+'/'+file+' -to- '+ backup_location+file
			shutil.copyfile(location+'/'+file, serverDir+'upstage/'+file)
			print 'copied: '+ location+'/'+file+' -to- '+ serverDir+'upstage/'+file


"""

Execute the script.

"""
if(len(sys.argv) >= 2):
	if(sys.argv[1] == 'cc'):
		# now compile using mtasc and swfmill
		compile_client()

		# if(sys.argv[2] == None):
		# 	print "Compile client.."
			# print "Usage: python install.py cc /path/to/flex/compiler/"
		# else:
		# 	# compile_client(sys.argv[2])
		# 	# print 'Client compiled Sucessfully! You can now create a deb file or install from source using:'
		# 	print 'To create a deb file: '
		# 	print 'sudo python install.py deb'
		# 	print 'To install from source: '
		# 	print 'sudo python install.py'
	elif(sys.argv[1] == 'deb' and len(sys.argv) > 2):
		print "Changing permissions for install scripts."
		os.system('chmod 755 '+appServerDir+'/DEBIAN/*')
		generate_deb(sys.argv[2])
	elif(sys.argv[1] == 'deb'):
		print "Changing permissions for install scripts."
		os.system('chmod 755 '+appServerDir+'/DEBIAN/*')
		generate_deb('')# usage python install.py deb

else:
	print "Removing .git files from current directory and all subdirectories..."
	os.system('rm -rf `find . -type d -name .git`')
	copyFiles(appServerDir, True)
	finalizeSetup()


#print "flex-config.xml created. Please copy the file to <flex compile location><frameworks>"

		#<source-path><path-element>/home/heath/upstage/client/upstage/</path-element></source-path>

#elif (len(sys.argv) == 3):
#    if(sys.argv[1] == 'deb' and len(sys.argv[2]) >1):
#        generate_deb(sys.argv[2])
#else:
#	print appServerDir
#	copyFiles(appServerDir, True)
#	finalizeSetup()
