#!/bin/bash
#Ridiculous random waypoint generator for GPX testing...
#You can change the number of WPTs contained in the output by specifying a parameter

BASEDATE=`date +%s`
BASELAT=`echo "($RANDOM-16000) % 40"|bc`
BASELON=`echo "($RANDOM-16000) % 40"|bc`
if [ $# -eq 1 ];
then
  NRPOINTS=$1
else
  NRPOINTS=1000
fi
STEPLEN=0.0001

echo '<?xml version="1.0"?>'
echo '<gpx version="1.1" creator="OpenCPN" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">'
for i in $(seq 1 $NRPOINTS)
do
  LAT=`echo "($BASELAT+$STEPLEN*($RANDOM-16000))%90" | bc`
  LON=`echo "($BASELAT+$STEPLEN*($RANDOM-16000))%180" | bc`
  GUID=`uuidgen`
  DATES=`expr $BASEDATE + $i`
  DATE=`date -d @$DATES +%Y-%m-%dZ%H:%M:%S`
  echo "<wpt lat=\"$LAT\" lon=\"$LON\">"
  echo '<type>WPT</type>'
  echo "<time>$DATE</time>"
  echo "<name>W$i</name>"
  echo '<sym>triangle</sym>'
  echo '<extensions>'
  echo "<opencpn:guid>$GUID</opencpn:guid>"
  echo '<opencpn:viz>1</opencpn:viz>'
  echo '<opencpn:viz_name>1</opencpn:viz_name>'
  echo '</extensions>'
  echo '</wpt>'
done
echo '</gpx>'
