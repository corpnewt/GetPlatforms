#!/usr/bin/env python
import os, sys, time, base64, binascii

os.chdir(os.path.dirname(os.path.realpath(__file__)))

# Python-aware urllib stuff
if sys.version_info >= (3, 0):
    from urllib.request import urlopen
else:
    from urllib2 import urlopen
    
# Set default vars
gma_url = "https://sourceforge.net/p/cloverefiboot/code/HEAD/tree/rEFIt_UEFI/Platform/gma.c?format=raw"

def _get_string(url):
    response = urlopen(url)
    CHUNK = 16 * 1024
    bytes_so_far = 0
    try:
        total_size = int(response.headers['Content-Length'])
    except:
        total_size = -1
    chunk_so_far = "".encode("utf-8")
    while True:
        chunk = response.read(CHUNK)
        bytes_so_far += len(chunk)
        if not chunk:
            break
        chunk_so_far += chunk
    return chunk_so_far.decode("utf-8")

def _get_gma():
    if os.path.exists("gma.c"):
        print("Found gma.c - loading...")
        data = ""
        with open('gma.c', 'r') as myfile:
            data = myfile.read()
        if len(data):
            return data
        print("File was empty!")
    # Didn't find it locally - try to get it from the URL
    print("Attempting to download gma.c...")
    try:
        data = _get_string(gma_url)
    except Exception as e:
        print(str(e))
        data = None
    return data

output = ""
primed = False
data = _get_gma()

if not data or not len(data):
    # Nothing returned
    print("Could not locate gma.c locally or remotely.  Exititing...")
    time.sleep(3)
    exit(1)
    
print("Got data!  Processing...")
    
for line in data.split("\n"):
    if line.lower().startswith("uint8") and ( "ig_vals" in line.lower() or "snb_vals" in line.lower() ):
        # got an opener - get the title
        title = line.split(" ")[1].split("_ig_vals")[0].split("_snb_vals")[0]
        if len(output):
            output += "\n\n"
        t_append  = " ig-platform-id's:\n\n" if "ig_vals" in line.lower() else " snb-platform-id's:\n\n"
        output += title + t_append
        output += "       Hex        Hex-Swap      Base64\n\n"
        primed = True
        continue
    if not primed:
        continue
    # Got something
    if line.startswith("};"):
        primed = False
        continue
    ids = line.split("{ ")[1].split(" },")[0]
    ig = ""
    ig_swap = ""
    for i in ids.split(", "):
        ig = i[2:] + ig
        ig_swap = ig_swap + i[2:]
    ig = "0x" + ig
    desc = line.split("},")[1]
    output += "   {}  -  {}  -  {}{}\n".format(
        ig,
        ig_swap,
        base64.b64encode(binascii.unhexlify(ig_swap.encode("utf-8"))).decode("utf-8"),
        desc
    )
    
if not len(output):
    # Nothing returned
    print("Got no platform-id's!  Exiting...")
    time.sleep(3)
    exit(1)

with open("platform-ids.txt", "w") as f:
    f.write(output)

print("Successfully created platform-ids.txt!")
time.sleep(3)
