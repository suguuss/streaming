from PIL import Image
from scapy.all import *
import cv2
from time import time

def pixel_to_byte(pixel):
	r, g, b = pixel

	h = f"{r:02x}{g:02x}{b:02x}"
	a = [h[x:x+2][::-1] for x in range(0, len(h), 2)]

	# print(a)

	return bytes.fromhex("".join(a))

def list_pxl_to_bytestr(pxl_list):
	out = b""

	for pxl in pxl_list:
		out += pixel_to_byte(pxl)

	return out


def send(data):
	MAC_DST			= "00:11:22:33:44:55"
	INTERFACE_ID 	= 3
	SEND_COUNT		= 1

	p = Ether(dst=MAC_DST, type=0) / (data)
	sendp(p, iface=conf.ifaces.dev_from_index(INTERFACE_ID), count=SEND_COUNT, verbose=False)



# Test image
img = Image.open("test_image.jpg").convert("RGB")
im = img.resize((320, 180))
pixels = list(im.getdata())


PIXELS_PER_PACKET = 500

cam = cv2.VideoCapture(1)

while True:

	st = time()

	# Image from camera
	
	s, img = cam.read()
	if not s: continue

	img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
	im = img.resize((320, 180))
	pixels = list(im.getdata())

	for x in range(0, len(pixels), PIXELS_PER_PACKET):
		data = list_pxl_to_bytestr(pixels[x:x+PIXELS_PER_PACKET])
		if len(data) < PIXELS_PER_PACKET*3:
			data += b"\x00" * (PIXELS_PER_PACKET*3 - len(data))

		send(data)

	# 	break

	t = time() - st
	print(f"took {t:.3f} ms | {1/t:.2f} fps", end="\r")