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
mpdevfile=/tmp/mkmpdevlist.txt
# This should be a pattern for sed -n to include only the manufacturers we want.
manuf=' s/Pliant *//p ; s/SEAGATE *//p'

# Shouldn't need to modify below here.

#
# Make a list of all devices, and report enclosure, slot and serial number
#
$SAS2IRCU $SASCARD display | sed -n '/Enclosure #/,/Enclosure#/p' \
	| sed -n 's/  Enclosure #.*: /e/p ; s/  Slot.*: /s/p ; s/  Serial.*: /:/p ; s/  Manuf.*: //p' \
	| sed -e 'N;N;N;s/\n//g'  \
	| sed -n "${manuf}" > $labelsfile

#
# Make a list of all /dev/da*, and report serial numbers
#
for i in /dev/da* ; do
	sn=`camcontrol inq $i -S`
	echo "$sn:$i"
done | sort > $devsnsfile
touch $mpdevfile
rm $mpdevfile
touch $mpdevfile

for sn in `cat $devsnsfile | cut -d: -f 1` ; do
	echo "Considering SN $sn"
	labcount=`grep -c $sn $labelsfile`
	if [ $labcount -eq 1 ] ; then
		echo "Found exactly one label.  This is good."
		devlabel=`grep $sn $labelsfile | cut -d: -f1`
		echo $devlabel
		grep -q "$devlabel " $mpdevfile
		r=$?
		if [ r -eq 0 ] ; then
			echo "Already considered $devlabel.  Skipping this device."
		else
			devcount=`grep -c $sn $devsnsfile`
			if [ $devcount -gt 1 ] ; then
				echo "Found more than one path to device.  This is good."
				grep -n $sn $devsnsfile
				devlist=''
				for i in `grep  $sn /tmp/mkmpdevsn.txt | cut -f 2 -d:` ; do 
					devlist="${devlist} $i"
				done

				echo $devlabel $devlist >> $mpdevfile

			else
				echo "Did not find more than one path.  Skipping this device."
				grep -n $sn $devsnsfile
			fi
		fi
	else
		echo "Did not find a unique label.  Skipping this device."
		grep -n $sn $labelsfile
	fi
done




