from xbee import ZigBee
import serial

from struct import unpack

import httplib2

ser = serial.Serial('/dev/tty.usbserial-A600ezgH', 38400)

xbee = ZigBee(ser, escaped=True)

def decodeFloat(var):
	text = ""
	for i in range(0, len(var)):
		text += var[i]
	return unpack('f', text)[0]

while True:
	try:
		response = xbee.wait_read_frame()
		#print response
	except KeyboardInterrupt:
		break
	if (response.get("rf_data")):
		h = httplib2.Http()
		resp, content = h.request("http://localhost/emoncms2/api/post?apikey=2c0915af95786b73d841da00da68b5fa&json={real_power:" + str(decodeFloat(response.get("rf_data")[0:4])) + ",apparent_power:" + str(decodeFloat(response.get("rf_data")[4:8])) + ",power_factory:" + str(decodeFloat(response.get("rf_data")[8:12])) + ",vrms:" + str(decodeFloat(response.get("rf_data")[12:16])) + ",irms:" + str(decodeFloat(response.get("rf_data")[16:20])) + "}")
		#print "Tamanho:|" + str(len(response.get("rf_data"))) + "|"
		#print "Real Power:|" + str(decodeFloat(response.get("rf_data")[0:4])) + "|"
		#print "Apparent Power:|" + str(decodeFloat(response.get("rf_data")[4:8])) + "|"
		#print "Power Factor:|" + str(decodeFloat(response.get("rf_data")[8:12])) + "|"
		#print "Vrms:|" + str(decodeFloat(response.get("rf_data")[12:16])) + "|"
		#print "Irms:|" + str(decodeFloat(response.get("rf_data")[16:20])) + "|"
		#print ""

ser.close()