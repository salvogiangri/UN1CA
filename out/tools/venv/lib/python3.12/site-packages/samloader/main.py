# SPDX-License-Identifier: GPL-3.0+
# Copyright (C) 2020 nlscc

import argparse
import os
import base64
import xml.etree.ElementTree as ET
import datetime
from tqdm import tqdm

from . import request
from . import crypt
from . import fusclient
from . import versionfetch
from . import imei
from .logging import log_to_file
from .logging import log_response
import xml.dom.minidom

def main():
    parser = argparse.ArgumentParser(description="Download and query firmware for Samsung devices.")
    parser.add_argument("-m", "--dev-model", help="device model", required=True)
    parser.add_argument("-r", "--dev-region", help="device region code", required=True)
    parser.add_argument("-i", "--dev-imei", help="Device IMEI or First 8 digits (TAC Index) to attempt generating a valid IMEI")
    parser.add_argument("-s", "--dev-serial", help="Device Serial Number if it does not have an IMEI number")
    subparsers = parser.add_subparsers(dest="command")
    dload = subparsers.add_parser("download", help="download a firmware")
    dload.add_argument("-v", "--fw-ver", help="firmware version to download", required=False)
    dload.add_argument("-R", "--resume", help="resume an unfinished download", action="store_true")
    dload.add_argument("-M", "--show-md5", help="print the expected MD5 hash of the downloaded file", action="store_true")
    dload.add_argument("-D", "--do-decrypt", help="auto-decrypt the downloaded file after downloading", action="store_true")
    dload_out = dload.add_mutually_exclusive_group(required=True)
    dload_out.add_argument("-O", "--out-dir", help="output the server filename to the specified directory")
    dload_out.add_argument("-o", "--out-file", help="output to the specified file")
    chkupd = subparsers.add_parser("checkupdate", help="check for the latest available firmware version")
    decrypt = subparsers.add_parser("decrypt", help="decrypt an encrypted firmware")
    decrypt.add_argument("-v", "--fw-ver", help="encrypted firmware version", required=True)
    decrypt.add_argument("-V", "--enc-ver", type=int, choices=[2, 4], default=4, help="encryption version (default 4)")
    decrypt.add_argument("-i", "--in-file", help="encrypted firmware file input", required=True)
    decrypt.add_argument("-o", "--out-file", help="decrypted firmware file output", required=True)
    args = parser.parse_args()
    # Log the command and arguments
    log_to_file(f"Command: {' '.join(os.sys.argv)}")
    if args.command == "download":
        imei_parser(args)
        download(args)
    elif args.command == "checkupdate":
        print(versionfetch.getlatestver(args.dev_model, args.dev_region))
    elif args.command == "decrypt":
        imei_parser(args)
        getkey = crypt.getv4key if args.enc_ver == 4 else crypt.getv2key
        key = getkey(args.fw_ver, args.dev_model, args.dev_region, args.dev_imei)
        length = os.stat(args.in_file).st_size
        with open(args.in_file, "rb") as inf:
            with open(args.out_file, "wb") as outf:
                crypt.decrypt_progress(inf, outf, key, length)

def download(args):
    client = fusclient.FUSClient()

    if not args.fw_ver:
        args.fw_ver = versionfetch.getlatestver(args.dev_model, args.dev_region)
    path, filename, size = getbinaryfile(client, args.fw_ver, args.dev_model, args.dev_region, args.dev_imei)
    out = args.out_file if args.out_file else os.path.join(args.out_dir, filename)
    # Print information
    print("Device : " + args.dev_model)
    print("CSC : " + args.dev_region)
    print("FW Version : " + args.fw_ver)
    print("FW Size : {:.3f} GB".format(size / (1024**3)))
    print("File Path : " + out)
    # Log the device information
    log_to_file(f"Device: {args.dev_model}")
    log_to_file(f"CSC: {args.dev_region}")
    log_to_file(f"FW: {args.fw_ver}")
    log_to_file(f"Path: {out}")
    # Auto-Resume
    if os.path.isfile(out.replace(".enc4", "")):
        print("File already downloaded and decrypted!")
        log_to_file("File already downloaded and decrypted!")
        return
    elif os.path.isfile(out):
        args.resume = True
        print("Resuming", filename)
        log_to_file(f"Resuming: {filename}")
    else:
        print("Downloading", filename)
        log_to_file(f"Downloading: {filename}")
    dloffset = os.stat(out).st_size if args.resume else 0
    if dloffset == size:
        print("already downloaded!")
        if os.path.isfile(out):
            print("FW Downloaded but not decrypted")
            log_to_file("FW Downloaded but not decrypted")
            # Auto decrypt
            auto_decrypt(args, out, filename)
        return
    fd = open(out, "ab" if args.resume else "wb")
    initdownload(client, filename)
    r = client.downloadfile(path+filename, dloffset)
    if args.show_md5 and "Content-MD5" in r.headers:
        print("MD5:", base64.b64decode(r.headers["Content-MD5"]).hex())

    log_interval = size // 10  # Log every 10%
    progress = dloffset

    # Download and log progress
    with tqdm(total=size, initial=dloffset, unit="B", unit_scale=True) as pbar:
        for chunk in r.iter_content(chunk_size=0x10000):
            if chunk:
                fd.write(chunk)
                fd.flush()
                pbar.update(len(chunk))
                
                # Update progress
                progress += len(chunk)
                
                # Check if it's time to log the progress
                if progress >= log_interval:
                    log_to_file(f"Download progress: {progress / (1024**2):.2f} MB / {size / (1024**2):.2f} MB")
                    log_interval += size // 10

    fd.close()
    log_to_file("Download completed.")
    # Auto decrypt
    auto_decrypt(args, out, filename)

def imei_parser(args):
    if args.dev_imei:
        if len(args.dev_imei) == 8:
            for attempt in range(1, 6):  # Try 5 times to generate a valid IMEI
                result = imei.generate_random_imei(args.dev_imei)
                client = fusclient.FUSClient()
                fw_ver = versionfetch.getlatestver(args.dev_model, args.dev_region)
                try:
                    req = request.binaryinform(fw_ver, args.dev_model, args.dev_region, result, client.nonce)
                    resp = client.makereq("NF_DownloadBinaryInform.do", req)
                    root = ET.fromstring(resp)
                    status = int(root.find("./FUSBody/Results/Status").text)
                    if status == 200:
                        print(f"Attempt {attempt}: Valid IMEI Found: {result}")
                        args.dev_imei = result
                        break
                    else:
                        print(f"Attempt {attempt}: IMEI {result} is invalid. FUS Returned : {status}")
                except Exception as e:
                    print(f"Attempt {attempt}: Error during binary file download: {e}")
            else:
                print("Unable to find a valid IMEI after 5 tries. Re-run Samloader to try again or pass a known valid IMEI or Serial Number")
                exit()
        elif len(args.dev_imei) == 15:
            print("IMEI is provided: " + args.dev_imei)
        else:
            print("Invalid IMEI length. Please provide either 8 or 15 digits.")
            exit()
    elif args.dev_serial:
        print("Serial Number is provided: " + args.dev_serial)
        args.dev_imei = args.dev_serial
    else:
        print("IMEI or Serial Number is required for download\nplease set a valid 15 digit IMEI or 8 Digit Tac Index to try generating one with -i / --dev-imei\nOr set a valid Serial Number with -s / --dev-serial")
        exit()

def auto_decrypt(args, out, filename):
    dec = out.replace(".enc4", "").replace(".enc2", "") # TODO: use a better way of doing this
    if os.path.isfile(dec):
        print("file {dec} already exists, refusing to auto-decrypt!")
        return
    print("\ndecyrpting", out)
    getkey = crypt.getv2key if filename.endswith(".enc2") else crypt.getv4key
    key = getkey(args.fw_ver, args.dev_model, args.dev_region, args.dev_imei)
    length = os.stat(out).st_size
    with open(out, "rb") as inf:
        with open(dec, "wb") as outf:
            crypt.decrypt_progress(inf, outf, key, length)
    os.remove(out)
    print("\nFile", out + " Has been Decrypted.")
    log_to_file("Decryption completed.")

def initdownload(client, filename):
    req = request.binaryinit(filename, client.nonce)
    resp = client.makereq("NF_DownloadBinaryInitForMass.do", req)

def getbinaryfile(client, fw, model, region, imei):
    req = request.binaryinform(fw, model, region, imei, client.nonce)
    resp = client.makereq("NF_DownloadBinaryInform.do", req)
    
    # Log the XML response directly
    log_response(f"Generated Binary Request at BinaryInform for {model}, {region}\n{resp}")

    root = ET.fromstring(resp)
    status = int(root.find("./FUSBody/Results/Status").text)
    if status != 200:
        raise Exception("DownloadBinaryInform returned {}, firmware could not be found?".format(status))
    filename = root.find("./FUSBody/Put/BINARY_NAME/Data").text
    if filename is None:
        raise Exception("DownloadBinaryInform failed to find a firmware bundle")
    size = int(root.find("./FUSBody/Put/BINARY_BYTE_SIZE/Data").text)
    path = root.find("./FUSBody/Put/MODEL_PATH/Data").text
    return path, filename, size
