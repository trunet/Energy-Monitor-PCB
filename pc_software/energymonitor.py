from xbee import ZigBee
import serial

from struct import unpack, pack

import httplib2

ser = serial.Serial('/dev/tty.usbserial-A600ezgH', 38400)

xbee = ZigBee(ser, escaped=True)

def decodeFloat(var):
	text = ""
	for i in range(0, len(var)):
		text += var[i]
	return unpack('f', text)[0]

def decodeInt(var):
	text = ""
	for i in range(0, len(var)):
		text += var[i]
	return unpack('h', text)[0]

addr = "\x00\x13\xA2\x00\x40\x5D\x35\x04"
vcal = 0.270419
ical = 0.170732
phasecal = 2.3
delay = 10000 # in milliseconds(10000 = 10 seconds)

# VCAL in 8-bits chunks
vcal = unpack('<L', pack('<f', vcal))[0]
v1 = vcal & 0xff
v2 = (vcal >> 8) & 0xff
v3 = (vcal >> 16) & 0xff
v4 = (vcal >> 24) & 0xff

# ICAL in 8-bits chunks
ical = unpack('<L', pack('<f', ical))[0]
i1 = ical & 0xff
i2 = (ical >> 8) & 0xff
i3 = (ical >> 16) & 0xff
i4 = (ical >> 24) & 0xff

# PHASECAL in 8-bits chunks
phasecal = unpack('<L', pack('<f', phasecal))[0]
p1 = phasecal & 0xff
p2 = (phasecal >> 8) & 0xff
p3 = (phasecal >> 16) & 0xff
p4 = (phasecal >> 24) & 0xff

# DELAY in 8-bits chunks
d1 = delay & 0xff
d2 = delay >> 8

#Set VCAL
#xbee.send("tx", frame_id="\x01", dest_addr_long=addr, dest_addr="\xff\xfe", data="\x01" + chr(v1) + chr(v2) + chr(v3) + chr(v4))
#Set ICAL
#xbee.send("tx", frame_id="\x01", dest_addr_long=addr, dest_addr="\xff\xfe", data="\x02" + chr(i1) + chr(i2) + chr(i3) + chr(i4))
#Set PHASECAL
#xbee.send("tx", frame_id="\x01", dest_addr_long=addr, dest_addr="\xff\xfe", data="\x03" + chr(p1) + chr(p2) + chr(p3) + chr(p4))
#Set DELAY
#xbee.send("tx", frame_id="\x01", dest_addr_long=addr, dest_addr="\xff\xfe", data="\x04" + chr(d1) + chr(d2))

#Get VCAL calibration
#xbee.send("tx", frame_id="\x01", dest_addr_long=addr, dest_addr="\xff\xfe", data="\x01")
#Get ICAL calibration
#xbee.send("tx", frame_id="\x01", dest_addr_long=addr, dest_addr="\xff\xfe", data="\x02")
#Get PHASECAL calibration
#xbee.send("tx", frame_id="\x01", dest_addr_long=addr, dest_addr="\xff\xfe", data="\x03")
#Get DELAY
#xbee.send("tx", frame_id="\x01", dest_addr_long=addr, dest_addr="\xff\xfe", data="\x04")

while True:
	try:
		response = xbee.wait_read_frame()
		#print response
	except KeyboardInterrupt:
		break
	if (response.get("rf_data")):
		if (response.get("rf_data")[0:1] == "\x01"):
			print "VCAL:|" + str(decodeFloat(response.get("rf_data")[1:5])) + "|"
		elif (response.get("rf_data")[0:1] == "\x02"):
			print "ICAL:|" + str(decodeFloat(response.get("rf_data")[1:5])) + "|"
		elif (response.get("rf_data")[0:1] == "\x03"):
			print "PHASECAL:|" + str(decodeFloat(response.get("rf_data")[1:5])) + "|"
		elif (response.get("rf_data")[0:1] == "\x04"):
			print "DELAY:|" + str(decodeInt(response.get("rf_data")[1:3])) + "|"
		else:
			#h = httplib2.Http()
			#resp, content = h.request("http://localhost/emoncms2/api/post?apikey=2c0915af95786b73d841da00da68b5fa&json={real_power:" + str(decodeFloat(response.get("rf_data")[0:4])) + ",apparent_power:" + str(decodeFloat(response.get("rf_data")[4:8])) + ",power_factory:" + str(decodeFloat(response.get("rf_data")[8:12])) + ",vrms:" + str(decodeFloat(response.get("rf_data")[12:16])) + ",irms:" + str(decodeFloat(response.get("rf_data")[16:20])) + "}")
			print "Tamanho:|" + str(len(response.get("rf_data"))) + "|"
			print "Real Power:|" + str(decodeFloat(response.get("rf_data")[0:4])) + "|"
			print "Apparent Power:|" + str(decodeFloat(response.get("rf_data")[4:8])) + "|"
			print "Power Factor:|" + str(decodeFloat(response.get("rf_data")[8:12])) + "|"
			print "Vrms:|" + str(decodeFloat(response.get("rf_data")[12:16])) + "|"
			print "Irms:|" + str(decodeFloat(response.get("rf_data")[16:20])) + "|"

ser.close()
