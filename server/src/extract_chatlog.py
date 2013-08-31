#!/usr/bin/python
#
# Description:
# ============
#
# extracts a chatlog from an upstage log (requires python 2.7)
# written by Martin Eisenbarth <eyesee@foobarlab.net>
#
# CHANGELOG:
# ==========
#
# Version 1.2:
# - added extraction of whisperings
# 
# Version 1.1:
# - fixed for UpStage 2.4.2
# - added geolocation host lookup
#
# Version 1.0:
# - initial version for UpStage 2.1
#
# TODO:
# =====
#
# - use paramters to call script (infile,outfile,options)
# ...
#

import re,urllib,hashlib,random,string

# set filenames accordingly
infile = open("upstage.log","r")
outfile = open("chat.log","w")

# set to 'True' to enable verbose output
printdebug = False

# lookup hosts to generate client id
hostlookup = True

# client ids
clients = {}

# salt for ip anonymization
salt = ''.join(random.choice(string.ascii_uppercase + string.digits) for x in range(16))

# match chat log entries
chat = re.compile(r"(.)*broadcasting (ANONTEXT|TEXT|SHOUT|THINK) \{(.)*")

# match whisperings
whispering = re.compile(r"(.)* SENT: message=whispered\+to\+(.)*&mode=MSG$")

# match join count log entries
joincount = re.compile(r"(.)*broadcasting JOINED \{(.)*")

# match join stage log entries 
joinstage = re.compile(r"(.)*RECEIVED: (.)+&mode=JOIN$")

# replace special chars (starting with \x..) to equivalent utf-8 char
special = re.compile(r'\\x(.{2})')
def usub(m): return urllib.unquote('%'+(m.group(1)))

print "Start processing ..."

if hostlookup:
	tmpclients = {}
	print "Hostlookup enabled."

for line in infile:

	line = line.strip()

	if printdebug:
		print "---------------------------------"
		print "LINE: %s" % line

	m = re.search('^(?P<date>\d{4}-\d{2}-\d{2})\s(?P<time>\d{2}:\d{2}:\d{2}[\+|\-]\d{4})\s(?P<socket>\[(\S)*\])\s(?P<content>(.)*)$',line)
	output = None
	if (m is None):
		pass
	else:
		date = m.group('date')
		time = m.group('time')
		socket = m.group('socket')
		content = m.group('content')

		if printdebug:
			print "DATE: %s" % date
			print "TIME: %s" % time
			print "SOCKET: %s" % socket

		# extract chatlogs

		content = content.strip()

		if printdebug:
			print "CONTENT: %s" % content
		
		if chat.match(line):
			m = re.search('^broadcasting (?P<texttype>(ANONTEXT|TEXT|SHOUT|THINK)) \{(?P<fields>(.)*)\}',content)
			texttype = m.group('texttype')
			fields = m.group('fields')
			
			if (texttype == 'TEXT'):
				m = re.search('\'text\': [\'|\"](?P<text>(.*))[\'|\"], \'ID\': [\'|\"](?P<uid>(.*))[\'|\"], \'name\': [\'|\"](?P<name>(.*))[\'|\"]',fields)
				text = m.group('text').strip()
				text = special.sub(usub, text)
				uid = m.group('uid')
				name = m.group('name').strip()
				output = "(%s) <%s> %s\n" % (uid,name,text)

			elif (texttype == 'ANONTEXT'):
				m = re.search('\'text\': [\'|\"](?P<text>(.*))[\'|\"]',fields)
				text = m.group('text').strip()
				text = special.sub(usub, text)
				output = "--- %s\n" % text
	
			elif (texttype == 'THINK'):
				m = re.search('\'thought\': [\'|\"](?P<thought>(.*))[\'|\"], \'ID\': [\'|\"](?P<uid>(.*))[\'|\"]',fields)
				thought = m.group('thought').strip()
				thought = special.sub(usub, thought)
				uid = m.group('uid')
				output = "(%s) { %s }\n" % (uid,thought)

			elif (texttype == 'SHOUT'):
				m = re.search('\'shout\': [\'|\"](?P<shout>(.*))[\'|\"], \'ID\': [\'|\"](?P<uid>(.*))[\'|\"]',fields)
				shout = m.group('shout').strip()
				shout = special.sub(usub, shout)
				uid = m.group('uid')
				output = "(%s) >> %s <<\n" % (uid,shout)

		# extract whisperings

		elif whispering.match(line):
			m = re.search('^SENT: message=whispered\+to\+(?P<receivers>(.*))%3A\+%22(?P<whisper>(.)*)%22&mode=MSG$',content)
			receivers = m.group('receivers')
			receivers = receivers.replace('+',' ')
			receivers = urllib.unquote(receivers)
			whisper = m.group('whisper')
			whisper = whisper.replace('+',' ')
			whisper = urllib.unquote(whisper)
			output = "... whispered '%s': %s\n" % (receivers,whisper)
			if printdebug:
				print "WHISPER TO '%s': %s" % (receivers,whisper)

		# extract joins

		elif joincount.match(line):
			m = re.search('^(player )?broadcasting JOINED \{(?P<fields>(.)*)\}',content)
			fields = m.group('fields')
			m = re.search('\'aCount\': [\'|\"](?P<audience>(.*))[\'|\"], \'pCount\': [\'|\"](?P<players>(.*))[\'|\"]',fields)
			audience = m.group('audience')
			players = m.group('players')
			if ((players == '0') and (audience == '0')):
				output = "==> COUNT CHANGED [P:0 A:0] (all visitors left stage)\n"
			else:
				output = "==> COUNT CHANGED [P:%s A:%s]\n" % (players, audience)


		elif joinstage.match(line):
			m = re.search('^RECEIVED: stage%5FID=(?P<stage>(.)*)&mode=JOIN',content)
			stage = m.group('stage')
			output = "==> JOINED STAGE '%s'\n" % stage
			if printdebug:
				print "JOINED: %s" % stage

		# finalize output: generate clientname, optionally do host lookup

		if (output is not None):

			# generate client id: extract IP+port from socket

			m = re.search('^\[(?P<stype>(.)*),(?P<port>\d{1,}),(?P<ip>(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))\]',socket)
			client = 'Unknown'
			if (m is None):
				pass
			else:
				stype = m.group('stype')
				port = m.group('port')
				ip = m.group('ip')
				anonid = hashlib.md5(ip+salt).hexdigest()
				#print "SOCKET: TYPE=%s, ADDRESS=%s, PORT=%s, ANON_ID=%s" % (stype,ip,port,anonid)
				client = anonid

				# host lookup 
				if hostlookup:	
					if client not in clients:

						response = urllib.urlopen('http://api.hostip.info/get_html.php?ip=%s'%ip).read()

						m = re.search('^Country: (?P<country>(.)*)\nCity: (?P<city>(.)*)\n',response)
						country=m.group('country')
						city=m.group('city')
						
						m = re.search('^(.)*\((?P<countrycode>(.)*)\)',country)
						countrycode = m.group('countrycode')
						
						m = re.search('^(?P<cityshort>([a-zA-Z ]*))',city)
						cityshort = m.group('cityshort')
						if cityshort != "":
							cityshort="_%s" % cityshort[0:20]

						# create unique clientname
						clientprefix = "%s%s" % (countrycode,cityshort)
						
						if clientprefix not in tmpclients:
							tmpclients[clientprefix]=1
						else:
							tmpclients[clientprefix]=tmpclients[clientprefix]+1
	
						count = tmpclients[clientprefix]
						
						clientname = "%s_%s" % (clientprefix, count)
						
						clients[client]=clientname
						client=clientname
						
						print "found new client: %s: %s, %s, %s" % (ip,clientname,country,city)

					else:
						client=clients[client]
			
			# pretty print client
			client = '[{0:20}]'.format(client.rjust(20))
			
			# write output
			output = "[%s %s] %s %s" % (date, time, client, output)
			outfile.write(output)

		if printdebug:
			print "OUTPUT: %s" % output

infile.close()
outfile.close()

print "Finished!"
