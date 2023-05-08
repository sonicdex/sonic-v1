import hashlib
import base64
import math
import binascii
import sys


principal_id_str = sys.argv[1]
subaccount = bytearray(32)
principal_id_str = principal_id_str.replace('-', '')
pad_length = math.ceil(len(principal_id_str) / 8) * 8 - len(principal_id_str)
principal_bytes = base64.b32decode(principal_id_str.encode('ascii') + b'=' * pad_length, True, None)
principal_bytes = principal_bytes[4:] # remove CRC32 checksum bytes
ADS = b"\x0Aaccount-id"
h = hashlib.sha224()
h.update(ADS)
h.update(principal_bytes)
h.update(subaccount)

checksum = binascii.crc32(h.digest())
checksum_bytes = checksum.to_bytes(4, byteorder='big')

identifier = checksum_bytes + h.digest()

print(identifier.hex())