#!/usr/local/bin/bash
#
# A script to look at the previous list of mappings of enclosure and slot to devices
# and attempt to return us to that state again.
# This script invokes gmultipath.
# ****** Use with extreme caution. ******
#
# Tristram Scott ts551@cam.ac.uk
# 15/10/2014
mpdevdir=/etc/mkmpdev
#mkmpdevlist.txt has enclosure and slot mapped to devices.  E.g. e3s0 /dev/da305 /dev/da6
mpdevfile=${mpdevdir}/mkmpdevlist.txt
for i in /dev/multipath/e*s* ; do 
dn=$(echo $i | sed -e 's/\/dev\/multipath\///')
d1=$(grep "$dn " $mpdevfile| cut -f2 -w | sed -e 's@/dev/@@') ; 
d2=$(grep "$dn " $mpdevfile | cut -f3 -w | sed -e 's@/dev/@@') ; 
d3=$(gmultipath getactive $dn); 
if [ `echo $d3 | wc -w` -lt 2 ] ; then 
	d4=$(echo $d1 | grep -v $d3 ; echo $d2 | grep -v $d3) ; gmultipath add $dn $d4 ; 
else d4="Nothing!" ; 
fi ; 
echo "+++ Device $dn had $d1 and $d2 and now has $d3.  We just added $d4" ; 
done
