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
manuf=' s/Pliant *//p ; s/SEAGATE *//p ; s/WD *//p'

# Shouldn't need to modify below here.
CREATEDEV=0
verb=0
showhelp=0
sfn=${0##*/} # Short version of our filename

qecho() {
if [ $verb -ne 0 ] ; then
echo $1
fi
}

showusage() {


cat << EOF
Usage: \
        $sfn -cv
        $sfn -c Create devices, rather than just enumerating them.
        $sfn -v Verbose mode.
Output will be written to $labelsfile, $devsnsfile and $mpdevfile.
EOF
}

while getopts +cv c
do
	case $c in
		c)	CREATEDEV=1;;
		v)	verb=1;;
		h|\?)
			showhelp=1
			showusage
			exit 1;;
	esac
done
#
# Make a list of all devices, and report enclosure, slot and serial number
#
echo "Making a list of devices in each enclsoure."
$SAS2IRCU $SASCARD display | sed -n '/Enclosure #/,/Enclosure#/p' \
	| sed -n 's/  Enclosure #.*: /e/p ; s/  Slot.*: /s/p ; s/  Serial.*: /:/p ; s/  Manuf.*: //p' \
	| sed -e 'N;N;N;s/\n//g'  \
	| sed -n "${manuf}" > $labelsfile

#
# Make a list of all /dev/da*, and report serial numbers
#
echo "Making a list of device serial numbers."
for i in `ls /dev/da* | sed -n '/\/dev\/da[0-9]*$/p'` ; do
	sn=`camcontrol inq $i -S`
	echo "$sn:$i"
done | sort > $devsnsfile
touch $mpdevfile
rm $mpdevfile
touch $mpdevfile

echo "Preparing mappings of multi path device labels and devices."
for sn in `cat $devsnsfile | cut -d: -f 1` ; do
	echo "Considering SN $sn"
	#
	# We look for a single match of our serial number in $labelsfile.
	# Unfortunately, sometimes there is a short and a long form, and 
	# we sometimes have the short form in $sn, the long in $labelsfile, 
	# and sometimes vice versa.  Hence we attempt to match against the 
	# longest substring that works, and hope it is unique.
	#
	nc=`echo $sn | wc -c`
	while [ $nc -gt 0 ] ; do
		ssn=$(echo $sn | cut -c1-$nc) 
		nc=$(grep -c $ssn $labelsfile)
		if [ $nc -gt 0 ] ; then 
			break 
		fi
	done
	labcount=`grep -c $ssn $labelsfile`
	if [ $labcount -eq 1 ] ; then
		echo "Found exactly one label.  This is good."
		devlabel=`grep $ssn $labelsfile | cut -d: -f1`
		echo $devlabel
		grep -q "$devlabel " $mpdevfile
		r=$?
		if [ $r -eq 0 ] ; then
			echo "Already considered $devlabel.  Skipping this device."
		else
			devcount=`grep -c $ssn $devsnsfile`
			if [ $devcount -gt 1 ] ; then
				echo "Found more than one path to device.  This is good."
				grep -n $ssn $devsnsfile
				devlist=''
				for i in `grep  $ssn /tmp/mkmpdevsn.txt | cut -f 2 -d:` ; do 
					devlist="${devlist} $i"
				done

				echo $devlabel $devlist >> $mpdevfile
				if [ $CREATEDEV -eq 1 ] ; then
					gmultipath create $devlabel $devlist
				fi

			else
				echo "Did not find more than one path.  Skipping this device."
				grep -n $ssn $devsnsfile
			fi
		fi
	else
		echo "Did not find a unique label.  Skipping this device."
		grep -n $sn $labelsfile
	fi
done




