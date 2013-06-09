#!/bin/bash
#Ridiculously long random track generator for GPX testing...
#You can change the number of TRKPTs contained in the output by specifying a parameter

GUID=`uuidgen`
BASEDATE=`date +%s`
BASELAT=`echo "($RANDOM-16000) % 40"|bc`
BASELON=`echo "($RANDOM-16000) % 40"|bc`
if [ $# -eq 1 ];
then
  NRTRKPOINTS=$1
else
  NRTRKPOINTS=10000
fi
STEPLEN=0.000001

echo '<?xml version="1.0"?>'
echo '<gpx version="1.1" creator="OpenCPN" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">'
echo '<trk>'
echo '<extensions>'
echo "<opencpn:guid>$GUID</opencpn:guid>"
echo '<opencpn:viz>1</opencpn:viz>'
echo '<opencpn:style style="101" />'
echo '</extensions>'
echo '<gpxx:TrackExtension>'
echo '<gpxx:DisplayColor>Blue</gpxx:DisplayColor>'
echo '</gpxx:TrackExtension>'
echo '<trkseg>'
LAT=$BASELAT
LON=$BASELON
for i in $(seq 1 $NRTRKPOINTS)
do
  LAT=`echo "($LAT+$STEPLEN*($RANDOM-14000))%80" | bc`
  LON=`echo "($LON+$STEPLEN*($RANDOM-14000))%180" | bc`
 
  DATES=`expr $BASEDATE + $i`
  DATE=`date -d @$DATES +%Y-%m-%dZ%H:%M:%S`
  echo "<trkpt lat=\"$LAT\" lon=\"$LON\">"
  echo "<time>$DATE</time>"
  echo '</trkpt>'
done
echo '</trkseg>'
echo '</trk>'
echo '</gpx>'

