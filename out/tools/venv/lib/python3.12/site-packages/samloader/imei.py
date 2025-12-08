""" Generate IMEIs """

# Generates valid IMEIs that can be used with the downloader
# The randomizer is based on observation on other IMEIs
# While its likely not perfect, the generated IMEIs so far worked with enough consistency that
# Providing a TAC is enough to initiate a download
# This is an alternative to providing your OWN imei just incase samsung has plans to block us
# The generator takes a TAC + 6 Random Digits + Generates Luhn check bit

import random
from . import request

def luhn_checksum(imei):
    imei += '0'
    parity = len(imei) % 2
    s = 0
    for idx, char in enumerate(imei):
        d = int(char)
        if idx % 2 == parity:
            d *= 2
            if d > 9:
                d -= 9
        s += d
    return (10 - (s % 10)) % 10

def generate_imei_numbers(tac, num_generated):
    imei_numbers = []

    for _ in range(num_generated):
        # Generate random 6-digit RNG with variations
        rng_first_digit = random.choice([0, 5, 7])
        rng_second_digit = random.randint(4, 9)
        rng_third_digit = random.choice([0, 1, 3, 5, 6, 7])
        rng_fourth_digit = random.randint(0, 9)
        rng_fifth_sixth = random.randint(00, 99)

        # Combine TAC and RNG
        tac_rng = "{}{:01d}{:01d}{:01d}{:01d}{:02d}".format(
            tac, rng_first_digit, rng_second_digit, rng_third_digit, rng_fourth_digit, rng_fifth_sixth
        )
        # Calculate Luhn check digit for TAC + RNG
        luhn_digit = luhn_checksum(tac_rng)

        # Combine all digits to form the IMEI number
        imei = int(f"{tac_rng}{luhn_digit:01d}")

        imei_numbers.append(imei)

    # Sort the list of IMEI numbers
    imei_numbers.sort()

    return imei_numbers

def generate_random_imei(tac):
    if len(str(tac)) == 15:
        return tac
    elif len(str(tac)) == 8:
        # Generate a random IMEI based on the provided TAC
        random_imei = generate_imei_numbers(tac, num_generated=1)
        return random_imei[0]
    else:
        print("Invalid IMEI length. Please provide a 15-digit IMEI or an 8-digit TAC.")
        return None
