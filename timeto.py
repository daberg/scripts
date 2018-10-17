#!/bin/python3


import datetime
import sys


if len(sys.argv) == 4:
    nostart = True

elif len(sys.argv) == 7:
    nostart = False

else:
    print("USAGE:")
    print("\tpython timeto.py [DAY]  [MONTH] [YEAR]")
    print("\tpython timeto.py [ENDD] [ENDM]  [ENDY] [STARTD] [STARTM] [STARTY]")
    sys.exit(1)

eday = int(sys.argv[1])
emonth = int(sys.argv[2])
eyear = int(sys.argv[3])

rem_d = (datetime.date(eyear, emonth, eday) - datetime.datetime.now().date()).days
rem_w = round(rem_d / 7, 1)
rem_y = round(rem_d / 365, 1)

if nostart:
    print("Remaining\t{}D\t{}W\t{}Y".format(rem_d, rem_w, rem_y))

else:
    sday = int(sys.argv[4])
    smonth = int(sys.argv[5])
    syear = int(sys.argv[6])

    ela_d = (datetime.datetime.now().date() - datetime.date(syear, smonth, sday)).days
    ela_w = round(ela_d / 7, 1)
    ela_y = round(ela_d / 365, 1)

    tot_d = rem_d + ela_d
    perc_rem_d = round(rem_d / tot_d * 100, 1)
    perc_ela_d = round(ela_d / tot_d * 100, 1)

    print("Remaining\t{}D\t{}W\t{}Y\t{}%".format(rem_d, rem_w, rem_y, rem_d))
    print("Elapsed  \t{}D\t{}W\t{}Y\t{}%".format(ela_d, ela_w, ela_y, ela_d))
