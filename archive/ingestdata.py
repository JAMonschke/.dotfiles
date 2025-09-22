# originally from Ashish Matthew as senddata.py
import os
import time
import requests
import json
import sys
import time

if len(sys.argv) != 4:
	print(" Arguments should be tenantname filename token")
	exit()

tenant = sys.argv[1]
filename = sys.argv[2]
token = sys.argv[3]

url = 'https://api.playground.scp.splunk.com/{0}/ingest/v1beta2/events'.format(tenant)
headers = {'Authorization': 'Bearer {0}'.format(token)}

p1=open(filename, 'r')

cnt = 0
incr = 1000
timestamp=time.time()
while True:
	d1=[]
	flg = 0
	print(url)
	
	for lines in range(incr):
		l1=p1.readline()
		if not l1:
			flg = 1
			break
		d2={'body': l1,'host':'testhost', 'source':'testsource', 'sourcetype':'testsourcetype', 'timestamp': int(timestamp)*1000}
		d1.append(d2)
		timestamp=timestamp-1
		
	retry = 3
	while retry > 0 :
		# print(json.dumps(d1))
		r = requests.post(url, data=json.dumps(d1), headers=headers)
		try:
			print(r.json())
		except:
			pass
			
		if r.status_code == 200:
			break
		else:
			print(r)
			print("Retrying sending events {0}".format(str(cnt)))
		time.sleep(1)
		retry -= 1
		
	if flg == 1:
		break
	cnt += incr
	print(str(cnt))
	if cnt % 30000 == 0:
		print("sent {0} events".format(str(cnt)))
	time.sleep(1)

p1.close()
