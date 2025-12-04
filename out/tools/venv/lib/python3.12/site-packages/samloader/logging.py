# SPDX-License-Identifier: GPL-3.0+
# Copyright (C) 2023 ananjaser1211

import datetime

# Main logging switch
logging_enabled = True
FUS = False
# Log file name
log_filename = "samloader.log"
response_filename = "FUS.log"

def log_to_file(message):
    if not logging_enabled:
        return

    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}\n"
    with open(log_filename, "a") as log_file:
        log_file.write(log_entry)

def log_response(message):
    if not FUS:
        return

    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}\n"
    with open(response_filename, "a") as log_file:
        log_file.write(log_entry)