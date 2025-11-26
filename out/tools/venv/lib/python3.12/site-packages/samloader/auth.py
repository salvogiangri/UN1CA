# SPDX-License-Identifier: GPL-3.0+
# Copyright (C) 2020 nlscc

""" FUS authentication functions (decrypting nonce, calculating auth token) """

import base64
from Cryptodome.Cipher import AES

# Constant key input values.
KEY_1 = "vicopx7dqu06emacgpnpy8j8zwhduwlh"
KEY_2 = "9u7qab84rpc16gvk"

# PKCS#7 padding functions.
pkcs_unpad = lambda d: d[:-d[-1]]
pkcs_pad = lambda d: d + bytes([16 - (len(d) % 16)]) * (16 - (len(d) % 16))

def aes_encrypt(inp: bytes, key: bytes) -> bytes:
    """ Perform an AES-CBC encryption. Encrypts /inp/ with key /key/. """
    enc_iv = key[:16] # IV is first 16 bytes of key
    cipher = AES.new(key, AES.MODE_CBC, enc_iv)
    return cipher.encrypt(pkcs_pad(inp))

def aes_decrypt(inp: bytes, key: bytes) -> bytes:
    """ Perform an AES-CBC decryption. Decrypts /inp/ with key /key/. """
    enc_iv = key[:16]
    cipher = AES.new(key, AES.MODE_CBC, enc_iv)
    return pkcs_unpad(cipher.decrypt(inp))

def derive_key(nonce: str) -> bytes:
    """ Calculate the AES key from the FUS input nonce. """
    key = ""
    # First 16 bytes are offsets into KEY_1
    for i in range(16):
        key += KEY_1[ord(nonce[i]) % 16]
    # Last 16 bytes are static
    key += KEY_2
    return key.encode()

def getauth(nonce: str) -> str:
    """ Calculate the response token from a given nonce. """
    nkey = derive_key(nonce)
    auth_data = aes_encrypt(nonce.encode(), nkey)
    return base64.b64encode(auth_data).decode()

def decryptnonce(inp: str) -> str:
    """ Decrypt the nonce returned by the server. """
    inp_data = base64.b64decode(inp)
    nonce = aes_decrypt(inp_data, KEY_1.encode()).decode()
    return nonce
