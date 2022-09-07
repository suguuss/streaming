from PIL import Image
from scapy.all import *
import cv2


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

img = Image.open("test_image.jpg").convert("RGB")
# # im = img.resize((192, 108))
im = img.resize((320, 180))
pixels = list(im.getdata())

# black 	= [(0,0,0)]  * len(pixels)
# blue 	= [(0,0,255)]  * len(pixels)
# green 	= [(255,0,0), (0,255,0), (0,0,255)]  * (len(pixels)//3)
# red 	= [(255,0,0)]  * len(pixels)
# white 	= [(255,255,255)]  * len(pixels)
# pixels = green

# print(green[:10])

while True:
	# s, img = cam.read()
	# if not s: continue

	# img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
	# im = img.resize((320, 180))
	# pixels = list(im.getdata())

	for x in range(0, len(pixels), 50):
		data = list_pxl_to_bytestr(pixels[x:x+50])
		if len(data) < 150:
			data += b"\x00" * (150 - len(data))

		# print(x / 50 + 1)
		# print(pixels[x:x+50])
		send(data)

	# 	break
	break