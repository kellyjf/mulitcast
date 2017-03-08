#!/usr/bin/python



import dns.message
import dns.rdataclass
import dns.rdatatype
import dns.query

# This way is just like nslookup/dig:

qname = dns.name.from_text('net111.local.')
q = dns.message.make_query(qname, dns.rdatatype.A)
resp = dns.query.udp(q,'224.0.0.251',port=5353, ttl=5)

for rec in resp.answer:
	print rec




