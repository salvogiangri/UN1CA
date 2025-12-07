# SPDX-License-Identifier: GPL-3.0+
# Copyright (C) 2020 nlscc

""" Build FUS XML requests. """

import xml.etree.ElementTree as ET
from .logging import log_response
import xml.dom.minidom

def getlogiccheck(inp: str, nonce: str) -> str:
    """ Calculate the request checksum for a given input and nonce. """
    if len(inp) < 16:
        raise Exception("getlogiccheck() input too short")
    out = ""
    for c in nonce:
        out += inp[ord(c) & 0xf]
    return out

def build_reqhdr(fusmsg: ET.Element):
    """ Build the FUSHdr of an XML message. """
    fushdr = ET.SubElement(fusmsg, "FUSHdr")
    ET.SubElement(fushdr, "ProtoVer").text = "1.0"

def build_reqbody(fusmsg: ET.Element, params: dict):
    """ Build the FUSBody of an XML message. """
    fusbody = ET.SubElement(fusmsg, "FUSBody")
    fput = ET.SubElement(fusbody, "Put")
    for tag, value in params.items():
        setag = ET.SubElement(fput, tag)
        sedata = ET.SubElement(setag, "Data")
        sedata.text = str(value)

def select_region():
    """ Prompt the user to select a region. """
    print("Select Region:")
    print("1) DE (Usually updates faster)")
    print("2) RO")
    
    choice = input("Select the Region you wish to use for EUX: ")
    
    if choice == "1":
        return "DE"
    elif choice == "2":
        return "RO"
    else:
        print("Invalid choice. Defaulting to DE.")
        return "DE"

def binaryinform(fwv: str, model: str, region: str, imei: str, nonce: str) -> str:
    """ Build a BinaryInform request. """
    fusmsg = ET.Element("FUSMsg")
    build_reqhdr(fusmsg)

    additional_fields = {}
    if region == "EUX":
        # By-pass region selector for now
        selected_region = "DE"
        additional_fields = {
            "DEVICE_AID_CODE": region,
            "DEVICE_CC_CODE": selected_region,
            "MCC_NUM": "262" if selected_region == "DE" else "226",
            "MNC_NUM": "01" if selected_region == "DE" else "10"
        }
    elif region == "EUY":
        additional_fields = {
            "DEVICE_AID_CODE": region,
            "DEVICE_CC_CODE": "RS",
            "MCC_NUM": "220",
            "MNC_NUM": "01"
        }

    build_reqbody(fusmsg, {
        "ACCESS_MODE": 2,
        "BINARY_NATURE": 1,
        "CLIENT_PRODUCT": "Smart Switch",
        "DEVICE_FW_VERSION": fwv,
        "DEVICE_LOCAL_CODE": region,
        "DEVICE_MODEL_NAME": model,
        "UPGRADE_VARIABLE": "0",
        "OBEX_SUPPORT": "0",
        "DEVICE_IMEI_PUSH": imei,
        "DEVICE_PLATFORM":"Android",
        "CLIENT_VERSION": "4.3.23123_1",
        "LOGIC_CHECK": getlogiccheck(fwv, nonce),
        **additional_fields  # Include additional fields if applicable
    })
    xml_response = xml.dom.minidom.parseString(ET.tostring(fusmsg, encoding="utf-8")).toprettyxml()
    log_response(f"Generated Binary Request at BinaryInform for {model}, {region}\n{xml_response}")
    return ET.tostring(fusmsg)

def binaryinit(filename: str, nonce: str) -> str:
    """ Build a BinaryInit request. """
    fusmsg = ET.Element("FUSMsg")
    build_reqhdr(fusmsg)
    checkinp = filename.split(".")[0][-16:]
    build_reqbody(fusmsg, {
        "BINARY_FILE_NAME": filename,
        "LOGIC_CHECK": getlogiccheck(checkinp, nonce)
    })
    return ET.tostring(fusmsg)
