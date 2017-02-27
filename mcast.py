#!/usr/bin/python

import struct
import socket
import signal
import urllib2
#import xmltodict
import xml.etree.cElementTree as ct
import argparse

parser=argparse.ArgumentParser()
parser.add_argument("--client", action="store_true", help="Run as a searching client")
args = parser.parse_args()

SSDP_ADDR = '239.255.255.250'
SSDP_PORT = 1900

MS = 'M-SEARCH * HTTP/1.1\r\nHOST: %s:%d\r\nMAN: "ssdp:discover"\r\nMX: 2\r\nST: ssdp:all\r\n\r\n' % (SSDP_ADDR, SSDP_PORT)


signal.signal(signal.SIGINT,signal.SIG_DFL)

s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.getprotobyname("udp"))

if args.client:
	b=struct.pack("i",5)
	s.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, b)
	s.sendto(MS,(SSDP_ADDR,SSDP_PORT))
else:
	s.bind(('',1900))
	a1=socket.inet_pton(socket.AF_INET, SSDP_ADDR)
	a2=struct.pack("=I",0)
	aa=a1+a2
	s.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, aa)

ssdpdict={}
while True:
	(retn,remaddr)=s.recvfrom(1000)
	lines=retn.split('\r\n')
	for line in lines:
		print remaddr,line
	
