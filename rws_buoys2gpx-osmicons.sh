#!/bin/bash
# Script to convert the buoy data from Dutch government's RWS CSV file into GPX format
# Author: nohal/dirk/
# Cleaned up and fixed by Jorrit (jorvi)
# Version 1.1 - 2017-05-22
# Licensed: GPLv3

# The original CSV data can be obtained from http://www.vaarweginformatie.nl/fdd/main/infra/downloads
# Order of items in input csv.xls file as of 22-05-2017
# https://www.vaarweginformatie.nl/fdd/main/infra/downloads
#1 VAARWATER;
#2 BENAM_COD;
#3 BENAMING;
#4 S57_ID;
#5 INBEDRIJF;
#6 Y_RD;
#7 X_RD;
#8 OBJ_SOORT;
#9 IALA_CAT;
#10 N_WGS_GMS;
#11 E_WGS_GMS;
#12 N_WGS_GM;
#13 E_WGS_GM;
#14 OBJ_VORM_C;
#15 OBJ_VORM;
#16 OBJ_KLEUR_C;
#17 OBJ_KLEUR;
#18 KLEURPATR_C;
#19 KLEURPATR;
#20 V_TT_C;
#21 TT_TOPTEK;
#22 TT_KLEUR_C;
#23 TT_KLEUR;
#24 TT_PAT_C;
#25 TT_KLR_PAT;
#26 SIGN_KAR_C;
#27 SIGN_KAR;
#28 SIGN_GR_C;
#29 SIGN_GROEP;
#30 SIGN_PERIO;
#31 RACON_CODE;
#32 LICHT_KL_C;
#33 LICHT_KLR;
#34 OPGEHEVEN;
#35 X_WGS84;
#36 Y_WGS84;

# --- Configuration of the generated GPX file format ---
ShowLightChar=1

FILE1="IJselmeerS.gpx"
LAT_MAX1=52.9
LAT_MIN1=52.2
LON_MIN1=4.55
LON_MAX1=6.1

FILE2="IJselmeerN_WaddenzeeW.gpx"
LAT_MAX2=53.5
LAT_MIN2=52.6
LON_MIN2=4.5
LON_MAX2=5.75

FILE3="WaddenzeeE.gpx"
LAT_MAX3=53.6
LAT_MIN3=53.1
LON_MIN3=5.2
LON_MAX3=7.2

NAME_VISIBLE=1 # Should the name be visible on the chart?
GENERATE_DESCRIPTION=1 #S hould the description containing all the data be generated?

# --- End of config, you should not need to modify anything belllow this line ---

# Write file header #
echo "<?xml version=\"1.0\"?>" > "${FILE1}"
echo "<gpx version=\"1.0\" creator=\"Convert script from RWS cvs file\">" >> ${FILE1}
echo "<?xml version=\"1.0\"?>" > "${FILE2}"
echo "<gpx version=\"1.0\" creator=\"Convert script from RWS cvs file\">" >> ${FILE2}
echo "<?xml version=\"1.0\"?>" > "${FILE3}"
echo "<gpx version=\"1.0\" creator=\"Convert script from RWS cvs file\">" >> ${FILE3}

while IFS=";" read -r -a LINE; do
  SYMBOL="bouy1"
  TOPMARK=""
  LIGHT=""
  LIGHT_TEXT=""
  COLOR=""
  LINE[35]=`echo ${LINE[35]} | sed -e 's/\,/./g'` #latitude with decimal point
  LINE[34]=`echo ${LINE[34]} | sed -e 's/\,/./g'` #longtitude with decimal point

  #### BuoySymbol #############
  if [ "${LINE[14]}" = "stomp" ]; then
    if [ "${LINE[16]}" = "Geel" ]; then SYMBOL='Can_Yellow'; fi;
    if [ "${LINE[16]}" = "Rood" ]; then SYMBOL='Can_Red'; fi;
    if [ "${LINE[16]}" = "Rood/wit repeterend" ]; then SYMBOL='Can_Red_White_Red_White'; fi;
    if [ "${LINE[16]}" = "Rood/groen repeterend" ]; then SYMBOL='Can_Red_Green_Red_Green'; fi;
    if [ "${LINE[16]}" = "Geel/zwart/geel" ]; then SYMBOL='Can_Yellow_Black_Yellow'; fi;
    if [ "${LINE[16]}" = "Zwart/geel/zwart" ]; then SYMBOL='Can_Black_Yellow_Black'; fi;
    if [ "${LINE[16]}" = "Zwart/geel" ]; then SYMBOL='Can_Black_Yellow'; fi;
    if [ "${LINE[16]}" = "Geel/zwart" ]; then SYMBOL='Can_Yellow_Black'; fi;
  fi;
  if [ "${LINE[14]}" = "spits" ]; then
    if [ "${LINE[16]}" = "Geel" ]; then SYMBOL='Cone_Yellow'; fi;
    if [ "${LINE[16]}" = "Groen" ]; then SYMBOL='Cone_Green'; fi;
    if [ "${LINE[16]}" = "Groen/wit repeterend" ]; then SYMBOL='Cone_Green_White_Green_White'; fi;
    if [ "${LINE[16]}" = "Rood" ]; then SYMBOL='Cone_Red'; fi;
  fi;
  if [ "${LINE[14]}" = "spar" ]; then
    if [ "${LINE[16]}" = "Geel" ]; then SYMBOL='Beacon_Yellow'; fi;
    if [ "${LINE[16]}" = "Groen" ]; then SYMBOL='Beacon_Green'; fi;
    if [ "${LINE[16]}" = "Rood" ]; then SYMBOL='Beacon_Red'; fi;
    if [ "${LINE[16]}" = "Groen/wit repeterend" ]; then SYMBOL='Beacon_Green_White_Green_White'; fi;
    if [ "${LINE[16]}" = "Rood/wit repeterend" ]; then SYMBOL='Beacon_Red_White_Red_White'; fi;
    if [ "${LINE[16]}" = "Zwart/rood/zwart" ]; then SYMBOL='Beacon_Black_Red_Black'; fi;
    if [ "${LINE[16]}" = "Geel/zwart/geel" ]; then SYMBOL='Beacon_Yellow_Black_Yellow'; fi;
    if [ "${LINE[16]}" = "Zwart/geel/zwart" ]; then SYMBOL='Beacon_Black_Yellow_Black'; fi;
    if [ "${LINE[16]}" = "Zwart/geel" ]; then SYMBOL='Beacon_Black_Yellow'; fi;
    if [ "${LINE[16]}" = "Geel/zwart" ]; then SYMBOL='Beacon_Yellow_Black'; fi;
  fi;
  if [ "${LINE[14]}" = "bol" ]; then
    if [ "${LINE[16]}" = "Groen/rood" ]; then SYMBOL='Sphere_Green_Red_Green'; fi;
    if [ "${LINE[16]}" = "Rood/groen" ]; then SYMBOL='Sphere_Red_Green_Red'; fi;
    if [ "${LINE[16]}" = "Rood/wit" ]; then SYMBOL='Sphere_Red_White'; fi;
    if [ "${LINE[16]}" = "Geel" ]; then SYMBOL='Sphere_Yellow'; fi;
  fi;
  if [ "${LINE[14]}" = "Pilaar" ]; then
    if [ "${LINE[16]}" = "Groen/rood/groen" ]; then SYMBOL='Pillar_Green_Red_Green'; fi;
    if [ "${LINE[16]}" = "Rood/groen/rood" ]; then SYMBOL='Pillar_Red_Green_Red'; fi;
    if [ "${LINE[16]}" = "Geel/zwart/geel" ]; then SYMBOL='Pillar_Yellow_Black_Yellow'; fi;
    if [ "${LINE[16]}" = "Zwart/geel/zwart" ]; then SYMBOL='Pillar_Black_Yellow_Black'; fi;
    if [ "${LINE[16]}" = "Zwart/geel" ]; then SYMBOL='Pillar_Black_Yellow'; fi;
    if [ "${LINE[16]}" = "Geel/zwart" ]; then SYMBOL='Pillar_Yellow_Black'; fi;
  fi;

  #### Topmarks #############
  if [ "${LINE[20]}" = "Cilinder" ]; then
    if [ "${LINE[22]}" = "Rood/wit/rood" ]; then
      if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_Can_Red_White_Red_Beacon"; fi;
      if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_Can_Red_White_Red_Buoy_Small"; fi;
    fi;
    if [ "${LINE[22]}" = "Rood" ]; then
      if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_Can_Red_Beacon"; fi;
      if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_Can_Red_Buoy_Small"; fi;
    fi;
  fi;
  if [ "${LINE[20]}" = "Kegel, punt naar boven" ]; then
      if [ "${LINE[22]}" = "Groen" ]; then
        if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_Cone_Green_Beacon"; fi;
        if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_Cone_Green_Beacon_Small"; fi;
      fi;
  fi;
  if [ "${LINE[20]}" = "Bol" ]; then
    if [ "${LINE[22]}" = "Rood/groen" ]; then
      if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_Sphere_Red_Green_Beacon"; fi;
      if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_Sphere_Red_Green_Buoy_Small"; fi;
    fi;
  fi;
  if [ "${LINE[20]}" = "2 Bollen" ]; then
    if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_Isol_Beacon"; fi;
    if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_Isol_Buoy_Small"; fi;
  fi;
  if [ "${LINE[20]}" = "2 Kegels, punten naar beneden" ]; then
    if [ "${LINE[14]}" = "Pilaar" ]; then TOPMARK="Top_South_Buoy"; fi;
    if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_South_Beacon"; fi;
    if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_South_Buoy_Small"; fi;
  fi;
  if [ "${LINE[20]}" = "2 Kegels punten van elkaar af" ]; then
    if [ "${LINE[14]}" = "Pilaar" ]; then TOPMARK="Top_East_Buoy"; fi;
      if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_East_Beacon"; fi;
      if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_East_Buoy_Small"; fi;
  fi;
  if [ "${LINE[20]}" = "2 Kegels, punten naar elkaar" ]; then
    if [ "${LINE[14]}" = "Pilaar" ]; then TOPMARK="Top_West_Buoy"; fi;
      if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_West_Beacon"; fi;
      if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_West_Buoy_Small"; fi;
  fi;
  if [ "${LINE[20]}" = "2 Kegels, punten naar boven" ]; then
    if [ "${LINE[14]}" = "Pilaar" ]; then TOPMARK="Top_North_Buoy"; fi;
      if [ "${LINE[14]}" = "spar" ]; then TOPMARK="Top_North_Beacon"; fi;
      if [ "${LINE[14]}" = "stomp" ]; then TOPMARK="Top_North_Buoy_Small"; fi;
  fi;

  #### Lights ################
  if [ "${LINE[26]}" != "Niet toegewezen" ]; then
    if [ "${LINE[32]}" = "Wit" ]; then LIGHT="Light_White_120"; fi;
    if [ "${LINE[32]}" = "Groen" ]; then LIGHT="Light_Green_120"; fi;
    if [ "${LINE[32]}" = "Rood" ]; then LIGHT="Light_Red_120"; fi;
    if [ "${LINE[32]}" = "Geel" ]; then LIGHT="Light_White_120"; fi;

    ### set char text
    if [ "${LINE[26]}" = "very quick-flash plus long- fl" ]; then LINE[26]="VQ+LFl"; fi;
    LIGHT_TEXT="$( cut -d '(' -f1 <<< "${LINE[26]}" )"

    if [ "${LINE[28]}" != "Niet toegewezen" ]; then LIGHT_TEXT=${LIGHT_TEXT}${LINE[28]}; fi;

    if [ "${LINE[32]}" = "Wit" ]; then COLOR="W "; fi;
    if [ "${LINE[32]}" = "Rood" ]; then COLOR="R "; fi;
    if [ "${LINE[32]}" = "Groen" ]; then COLOR="G "; fi;
    if [ "${LINE[32]}" = "Geel" ]; then COLOR="Y "; fi;
    LIGHT_TEXT=${LIGHT_TEXT}${COLOR}
    if [ "${LINE[29]}" != "#" ]; then LIGHT_TEXT=${LIGHT_TEXT}"${LINE[29]}""s"; fi;
  fi;

  #### Write to File ####
  if [ `expr "${LINE[35]}" '<' "${LAT_MAX1}"` -gt 0 ]; then
    if [ `expr "${LINE[35]}" '>' "${LAT_MIN1}"` -gt 0 ]; then
      if [ `expr "${LINE[34]}" '<' "${LON_MAX1}"` -gt 0 ]; then
        if [ `expr "${LINE[34]}" '>' "${LON_MIN1}"` -gt 0 ]; then
          echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE1}
          echo "  <type>WPT</type>" >> ${FILE1}
          if [ ${ShowLightChar} = 1 ]; then
            echo "  <name>""${LINE[2]}" >> ${FILE1}
            echo ${LIGHT_TEXT}"</name>" >> ${FILE1}
          else
            echo "  <name>""${LINE[2]}""</name>" >> ${FILE1}
          fi;
          echo "  <sym>"${SYMBOL}"</sym>" >> ${FILE1}
          echo "</wpt>" >> ${FILE1}
          if [ "${TOPMARK}" != "" ]; then
            echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE1}
            echo "  <sym>"${TOPMARK}"</sym>" >> ${FILE1}
            echo "</wpt>" >> ${FILE1}
          fi;
          if [ "${LIGHT}" != "" ]; then
            echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE1}
            echo "  <sym>"${LIGHT}"</sym>" >> ${FILE1}
            echo "</wpt>" >> ${FILE1}
          fi;
        fi;
      fi;
    fi;
  fi;

  if [ `expr "${LINE[35]}" '<' "${LAT_MAX2}"` -gt 0 ]; then
    if [ `expr "${LINE[35]}" '>' "${LAT_MIN2}"` -gt 0 ]; then
      if [ `expr "${LINE[34]}" '<' "${LON_MAX2}"` -gt 0 ]; then
        if [ `expr "${LINE[34]}" '>' "${LON_MIN2}"` -gt 0 ]; then
          echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE2}
          echo "  <type>WPT</type>" >> ${FILE2}
          if [ ${ShowLightChar} = 1 ]; then
            echo "  <name>""${LINE[2]}" >> ${FILE2}
            echo ${LIGHT_TEXT}"</name>" >> ${FILE2}
          else
            echo "  <name>""${LINE[2]}""</name>" >> ${FILE2}
          fi;
          echo "  <sym>"$SYMBOL"</sym>" >> ${FILE2}
          echo "</wpt>" >> ${FILE2}
          if [ "${TOPMARK}" != "" ]; then
            echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE2}
            echo "  <sym>"${TOPMARK}"</sym>" >> ${FILE2}
            echo "</wpt>" >> ${FILE2}
          fi;
          if [ "${LIGHT}" != "" ]; then
            echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE2}
            echo "  <sym>"${LIGHT}"</sym>" >> ${FILE2}
            echo "</wpt>" >> ${FILE2}
          fi;
        fi;
      fi;
    fi;
  fi;

  if [ `expr "${LINE[35]}" '<' "${LAT_MAX3}"` -gt 0 ]; then
    if [ `expr "${LINE[35]}" '>' "${LAT_MIN3}"` -gt 0 ]; then
      if [ `expr "${LINE[34]}" '<' "${LON_MAX3}"` -gt 0 ]; then
        if [ `expr "${LINE[34]}" '>' "${LON_MIN3}"` -gt 0 ]; then
          echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE3}
          echo "  <type>WPT</type>" >> ${FILE3}
          if [ ${ShowLightChar} = 1 ]; then
            echo "  <name>""${LINE[2]}" >> ${FILE3}
            echo ${LIGHT_TEXT}"</name>" >> ${FILE3}
          else
            echo "  <name>""${LINE[2]}""</name>" >> ${FILE3}
          fi;
          echo "  <sym>"$SYMBOL"</sym>" >> ${FILE3}
          echo "</wpt>" >> ${FILE3}
          if [ "${TOPMARK}" != "" ]; then
            echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE3}
            echo "  <sym>"${TOPMARK}"</sym>" >> ${FILE3}
            echo "</wpt>" >> ${FILE3}
          fi;
          if [ "${LIGHT}" != "" ]; then
            echo "<wpt lat=\"${LINE[35]}\" lon=\"${LINE[34]}\">" >> ${FILE3}
            echo "  <sym>"${LIGHT}"</sym>" >> ${FILE3}
            echo "</wpt>" >> ${FILE3}
          fi;
        fi;
      fi;
    fi;
  fi;

echo "${LINE[2]}", "${LINE[34]}", "${LINE[35]}"
done < $1

# Write file footer
echo "</gpx>" >> ${FILE1}
echo "</gpx>" >> ${FILE2}
echo "</gpx>" >> ${FILE3}
