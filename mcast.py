#!/usr/bin/python

import struct
import socket
import signal
import urllib2
#import xmltodict
import xml.etree.cElementTree as ct

SSDP_ADDR = '239.255.255.250'
SSDP_PORT = 1900

MS = 'M-SEARCH * HTTP/1.1\r\nHOST: %s:%d\r\nMAN: "ssdp:discover"\r\nMX: 2\r\nST: ssdp:all\r\n\r\n' % (SSDP_ADDR, SSDP_PORT)


signal.signal(signal.SIGINT,signal.SIG_DFL)

s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.getprotobyname("udp"))

#s.connect((SSDP_ADDR,SSDP_PORT))

a1=socket.inet_pton(socket.AF_INET, SSDP_ADDR)
a2=struct.pack("=I",0)
aa=a1+a2
b=struct.pack("i",5)
s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, b)
s.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, aa)

#s.bind(('',1900))
s.bind((SSDP_ADDR, 1900))
s.sendto(MS,(SSDP_ADDR,SSDP_PORT))

ssdpdict={}
while True:
	(retn,remaddr)=s.recvfrom(1000)
#	print remaddr
#	print retn
	
	lines=retn.split('\r\n')
	cmd=lines[0].split(' ')[0]
	print retn
	if cmd != 'NOTIFY':
		continue

	
	adict={}
	for line in lines[1:]:
		parts=line.split(":")
		key=parts[0]
		value=":".join(parts[1:])
		adict[key]=value	
		print remaddr,"%-12.12s %s"%(key,value)
		if key=='LOCATION':
			xml=urllib2.urlopen(value).read()
			xroot=ct.XML(xml)
			xdict=XmlDictConfig(xroot)
			print xdict.keys()

