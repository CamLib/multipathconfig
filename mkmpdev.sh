#!/usr/local/bin/bash
#
# Make multipath devices for /dev/da*
#
# Tristram Scott
# 29/07/2014

# Get a copy of sas2ircu from LSI.
SAS2IRCU=/usr/local/bin/sas2ircu
# Which SAS card do we talk to?  Sas2ircu list will help you decide.
SASCARD=0
labelsfile=/tmp/mkmpdevlabels.txt
devsnsfile=tmp/mkmpdevsn.txt
# This should be a pattern for sed -n to include only the manufacturers we want.
manuf=' s/Pliant //p ; s/SEAGATE //p'

# Shouldn't need to modify below here.

#
# Make a list of all devices, and report enclosure, slot and serial number
#
sas2ircu 0 display | sed -n '/Enclosure #/,/Enclosure#/p' \
	| sed -n 's/  Enclosure #.*: /e/p ; s/  Slot.*: /s/p ; s/  Serial.*: /SN/p ; s/  Manuf.*: //p' \
	| sed -n 'N;N;N;s/\n//g'  \
	| sed -n "${manuf}" > $labelsfile
