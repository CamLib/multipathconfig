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
devsnsfile=/tmp/mkmpdevsn.txt
# This should be a pattern for sed -n to include only the manufacturers we want.
manuf=' s/Pliant *//p ; s/SEAGATE *//p'

# Shouldn't need to modify below here.

#
# Make a list of all devices, and report enclosure, slot and serial number
#
$SAS2IRCU $SASCARD display | sed -n '/Enclosure #/,/Enclosure#/p' \
	| sed -n 's/  Enclosure #.*: /e/p ; s/  Slot.*: /s/p ; s/  Serial.*: /SerialNo/p ; s/  Manuf.*: //p' \
	| sed -e 'N;N;N;s/\n//g'  \
	| sed -n "${manuf}" > $labelsfile

#
# Make a list of all /dev/da*, and report serial numbers
#
for i in /dev/da* ; do
	sn=`camcontrol inq $i -S`
	echo $sn $i
done | sort > $devsnsfile
