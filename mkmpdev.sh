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

verecho
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
for i in /dev/da* ; do
	sn=`camcontrol inq $i -S`
	echo "$sn:$i"
done | sort > $devsnsfile
touch $mpdevfile
rm $mpdevfile
touch $mpdevfile

echo "Preparing mappings of multi path device labels and devices."
for sn in `cat $devsnsfile | cut -d: -f 1` ; do
	echo "Considering SN $sn"
	labcount=`grep -c $sn $labelsfile`
	if [ $labcount -eq 1 ] ; then
		echo "Found exactly one label.  This is good."
		devlabel=`grep $sn $labelsfile | cut -d: -f1`
		echo $devlabel
		grep -q "$devlabel " $mpdevfile
		r=$?
		if [ $r -eq 0 ] ; then
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
				if [ $CREATEDEV -eq 1 ] ;
					gmultipath create $devlabel $devlist
				fi

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




