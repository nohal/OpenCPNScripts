#!/bin/bash

# Script to convert the buoy data from Dutch government's RWS CSV file into GPX format
# Author: nohal
# Version 1.0 - 2013-05-31
# Licensed: GPLv2 or, at your will, later

#The input file is expected in the following format:
#VAARWATER;BENAM_COD;BENAMING;INBEDRIJF;X_RD;Y_RD;OBJ_SOORT;IALA_CAT;N_WGS_gms;E_WGS_gms;N_WGS_gm;E_WGS_gm;Obj_vorm_c;OBJ_VORM;Obj_kleur_c;OBJ_KLEUR;Kleurpatr_c;KLEURPATR;V_TT_c;TT_TOPTEK;TT_kleur_c;TT_KLEUR;TT_pat_c;TT_KLR_PAT;Sign_kar_c;SIGN_KAR;Sign_gr_c;SIGN_GROEP;SIGN_PERIO;RACON_CODE;Licht_kl_c;LICHT_KLR;OPGEHEVEN;X_WGS84;Y_WGS84;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#[KOPBAKENS]LAUWERSMEER;VW-KLM  -0125;KLM 2;01.01.2005; 598881,7548; 209807,7054;KB2;4;53.22.24.52;006.12.38.45;53.22.4087;006.12.6409;2;stomp;6;Geel;#;Niet toegewezen;5;Cilinder;3,1,3;Rood/wit/rood;1;Horizontaal;#;Niet toegewezen;#;Niet toegewezen;#;#;#;Niet toegewezen;#;6,210681;53,373478;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#...may more data lines...

# --- Configuration of the generated GPX file format ---

SYMBOL='bouy1'            #Symbol to be used for the WPT
NAME_VISIBLE=1            #Should the name be visible on the chart?
GENERATE_DESCRIPTION=1    #Should the description containing all the data be generated?

# --- End of config, you should not need to modify anything belllow this line ---

if [ $# -ne 2 ]; then
  printf "Usage: %s <RWS_data_file.csv> <Filter string>\n"
  printf "The whole dataset contains thousands of buoys and is hardly of any use.\n"
  printf "For that reason, consider generating just a subset using a filter.\n"
  printf "grep -E (aka egrep) is then used to filter the data according to the supplied filter\n"
  printf "Example: using \"VW-DD|VW-DO\" as a filter will output just the data for DOKKUMERDIEP and DOLLARD \n"
  printf ""
  exit 1
fi

CURDATE=`date +%Y-%m-%d`
CREATIONTS=`date -u +%Y-%m-%dT%H:%M:%SZ`

echo '<?xml version="1.0" encoding="utf-8" ?>'
echo '<gpx version="1.1" creator="OpenCPN" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" xmlns:opencpn="http://www.opencpn.org">'

tail -n +2 "$1" | grep -v "#WAARDE!$" | grep -E "$2" | while read LINE ; do
 GUID=`uuidgen`
 echo $LINE | awk -F";"  ' { gsub(/,/,".",$34); gsub(/,/,".",$35); print "<wpt lat=\""$35"\" lon=\""$34"\">"; }'
 echo "<time>$CREATIONTS</time>"
 echo $LINE | awk -F";"  ' { print "<name>"$3"</name>"; } '
 if [ $GENERATE_DESCRIPTION -eq 1 ]; then
  echo $LINE | awk -F";"  ' { print "<desc>VAARWATER: "$1"&#x0A;BENAM_COD: "$2"&#x0A;INBEDRIJF: "$4"&#x0A;X_RD: "$5"&#x0A;Y_RD: "$5"&#x0A;OBJ_SOORT: "$6"&#x0A;IALA_CAT: "$7"&#x0A;N_WGS_gms: "$8"&#x0A;E_WGS_gms: "$9"&#x0A;N_WGS_gm: "$10"&#x0A;E_WGS_gm: "$11"&#x0A;Obj_vorm_c: "$12"&#x0A;OBJ_VORM: "$13"&#x0A;Obj_kleur_c: "$14"&#x0A;OBJ_KLEUR: "$15"&#x0A;Kleurpatr_c: "$16"&#x0A;KLEURPATR: "$17"&#x0A;V_TT_c: "$18"&#x0A;TT_TOPTEK: "$19"&#x0A;TT_kleur_c: "$20"&#x0A;TT_KLEUR: "$21"&#x0A;TT_pat_c: "$22"&#x0A;TT_KLR_PAT: "$23"&#x0A;Sign_kar_c: "$24"&#x0A;SIGN_KAR: "$25"&#x0A;Sign_gr_c: "$26"&#x0A;SIGN_GROEP: "$27"&#x0A;SIGN_PERIO: "$28"&#x0A;RACON_CODE: "$29"&#x0A;Licht_kl_c: "$30"&#x0A;LICHT_KLR: "$31"&#x0A;OPGEHEVEN: "$32"</desc>"; } '
 fi
 echo "<sym>$SYMBOL</sym>"
 echo "<type>WPT</type>"
 echo "<extensions>"
 echo "<opencpn:guid>$GUID</opencpn:guid>"
 echo "<opencpn:viz>1</opencpn:viz>"
 echo "<opencpn:viz_name>$NAME_VISIBLE</opencpn:viz_name>"
 echo "</extensions>"
 echo '</wpt>'
done

echo '</gpx>'
