#!/bin/bash
# set -x
# Script to convert the buoy data from Dutch government's RWS CSV file into GPX format
# Author: nohal/dirk
# Version 1 - 2013-06-27
# Licensed: GPLv2 or, at your will, later

#The original CSV data can be obtained from http://www.vaarweginformatie.nl/fdd/main/infra/downloads
#At the time of creation of this script, the up-to-date file 130524_DNZ_002a_markeringen_drijvend was at http://www.vaarweginformatie.nl/fdd/main/download?fileId=25053804

#The input file is expected in the following format:
#VAARWATER;BENAM_COD;BENAMING;INBEDRIJF;X_RD;Y_RD;OBJ_SOORT;IALA_CAT;N_WGS_gms;E_WGS_gms;N_WGS_gm;E_WGS_gm;Obj_vorm_c;OBJ_VORM;Obj_kleur_c;OBJ_KLEUR;Kleurpatr_c;KLEURPATR;V_TT_c;TT_TOPTEK;TT_kleur_c;TT_KLEUR;TT_pat_c;TT_KLR_PAT;Sign_kar_c;SIGN_KAR;Sign_gr_c;SIGN_GROEP;SIGN_PERIO;RACON_CODE;Licht_kl_c;LICHT_KLR;OPGEHEVEN;X_WGS84;Y_WGS84;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#[KOPBAKENS]LAUWERSMEER;VW-KLM -0125;KLM 2;01.01.2005; 598881,7548; 209807,7054;KB2;4;53.22.24.52;006.12.38.45;53.22.4087;006.12.6409;2;stomp;6;Geel;#;Niet toegewezen;5;Cilinder;3,1,3;Rood/wit/rood;1;Horizontaal;#;Niet toegewezen;#;Niet toegewezen;#;#;#;Niet toegewezen;#;6,210681;53,373478;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#...may more data lines...

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

NAME_VISIBLE=1 #Should the name be visible on the chart?
GENERATE_DESCRIPTION=1 #Should the description containing all the data be generated?

# --- End of config, you should not need to modify anything belllow this line ---

# make file header #

echo "<?xml version=\"1.0\"?>" > "$FILE1"
echo "<gpx version=\"1.0\" creator=\"Convert script from RWS cvs file\">" >> $FILE1
echo "<?xml version=\"1.0\"?>" > "$FILE2"
echo "<gpx version=\"1.0\" creator=\"Convert script from RWS cvs file\">" >> $FILE2
echo "<?xml version=\"1.0\"?>" > "$FILE3"
echo "<gpx version=\"1.0\" creator=\"Convert script from RWS cvs file\">" >> $FILE3

while IFS=";" read -r -a LINE ; do
  SYMBOL="bouy1"
  TOPMARK=""
  LIGHT=""
  LIGHT_TEXT=""
  COLOR=""
  LINE[34]=`echo ${LINE[34]} | sed -e 's/\,/./g'` #latitude with decimalpoint
  LINE[33]=`echo ${LINE[33]} | sed -e 's/\,/./g'` #longitude

#### BuoySymbol ############# 

  if [ "${LINE[13]}" = "stomp" ] 
    then
      if [ "${LINE[15]}" = "Geel" ] ; then SYMBOL='Can_Yellow' ;fi
      if [ "${LINE[15]}" = "Rood" ] ; then SYMBOL='Can_Red' ;fi 
      if [ "${LINE[15]}" = "Rood/wit repeterend" ] ; then SYMBOL='Can_Red_White_Red_White' ;fi
      if [ "${LINE[15]}" = "Rood/groen repeterend" ] ; then SYMBOL='Can_Red_Green_Red_Green' ;fi
      if [ "${LINE[15]}" = "Geel/zwart/geel" ] ; then SYMBOL='Can_Yellow_Black_Yellow' ;fi
      if [ "${LINE[15]}" = "Zwart/geel/zwart" ] ; then SYMBOL='Can_Black_Yellow_Black' ;fi
      if [ "${LINE[15]}" = "Zwart/geel" ] ; then SYMBOL='Can_Black_Yellow' ;fi
      if [ "${LINE[15]}" = "Geel/zwart" ] ; then SYMBOL='Can_Yellow_Black' ;fi
  fi    
  if [ "${LINE[13]}" = "spits" ] 
    then
      if [ "${LINE[15]}" = "Geel" ] ; then SYMBOL='Cone_Yellow' ;fi
      if [ "${LINE[15]}" = "Groen" ] ; then SYMBOL='Cone_Green' ;fi
      if [ "${LINE[15]}" = "Groen/wit repeterend" ] ; then SYMBOL='Cone_Green_White_Green_White' ;fi
      if [ "${LINE[15]}" = "Rood" ] ; then SYMBOL='Cone_Red' ;fi
  fi
  if [ "${LINE[13]}" = "spar" ] 
    then
      if [ "${LINE[15]}" = "Geel" ] ; then SYMBOL='Beacon_Yellow' ;fi
      if [ "${LINE[15]}" = "Groen" ] ; then SYMBOL='Beacon_Green' ;fi
      if [ "${LINE[15]}" = "Rood" ] ; then SYMBOL='Beacon_Red' ;fi
      if [ "${LINE[15]}" = "Groen/wit repeterend" ] ; then SYMBOL='Beacon_Green_White_Green_White' ;fi
      if [ "${LINE[15]}" = "Rood/wit repeterend" ] ; then SYMBOL='Beacon_Red_White_Red_White' ;fi
      if [ "${LINE[15]}" = "Zwart/rood/zwart" ] ; then SYMBOL='Beacon_Black_Red_Black' ;fi
      if [ "${LINE[15]}" = "Geel/zwart/geel" ] ; then SYMBOL='Beacon_Yellow_Black_Yellow' ;fi
      if [ "${LINE[15]}" = "Zwart/geel/zwart" ] ; then SYMBOL='Beacon_Black_Yellow_Black' ;fi
      if [ "${LINE[15]}" = "Zwart/geel" ] ; then SYMBOL='Beacon_Black_Yellow' ;fi
      if [ "${LINE[15]}" = "Geel/zwart" ] ; then SYMBOL='Beacon_Yellow_Black' ;fi
  fi
  if [ "${LINE[13]}" = "bol" ] 
    then
      if [ "${LINE[15]}" = "Groen/rood" ] ; then SYMBOL='Sphere_Green_Red_Green' ;fi
      if [ "${LINE[15]}" = "Rood/groen" ] ; then SYMBOL='Sphere_Red_Green_Red' ;fi
      if [ "${LINE[15]}" = "Rood/wit" ] ; then SYMBOL='Sphere_Red_White' ;fi
      if [ "${LINE[15]}" = "Geel" ] ; then SYMBOL='Sphere_Yellow' ;fi
  fi
  
  if [ "${LINE[13]}" = "Pilaar" ] 
    then
      if [ "${LINE[15]}" = "Groen/rood/groen" ] ; then SYMBOL='Pillar_Green_Red_Green' ;fi
      if [ "${LINE[15]}" = "Rood/groen/rood" ] ; then SYMBOL='Pillar_Red_Green_Red' ;fi
      if [ "${LINE[15]}" = "Geel/zwart/geel" ] ; then SYMBOL='Pillar_Yellow_Black_Yellow' ;fi
      if [ "${LINE[15]}" = "Zwart/geel/zwart" ] ; then SYMBOL='Pillar_Black_Yellow_Black' ;fi
      if [ "${LINE[15]}" = "Zwart/geel" ] ; then SYMBOL='Pillar_Black_Yellow' ;fi
      if [ "${LINE[15]}" = "Geel/zwart" ] ; then SYMBOL='Pillar_Yellow_Black' ;fi
  fi
#### Topmarks #############

  if [ "${LINE[19]}" = "Cilinder" ] 
    then
      if [ "${LINE[21]}" = "Rood/wit/rood" ] ; then
        if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_Can_Red_White_Red_Beacon" ;fi
        if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_Can_Red_White_Red_Buoy_Small" ;fi
      fi
      if [ "${LINE[21]}" = "Rood" ] ; then
        if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_Can_Red_Beacon" ;fi
        if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_Can_Red_Buoy_Small" ;fi
      fi     
  fi
  if [ "${LINE[19]}" = "Kegel, punt naar boven" ] 
    then
      if [ "${LINE[21]}" = "Groen" ] ; then
        if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_Cone_Green_Beacon" ;fi
        if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_Cone_Green_Beacon_Small" ;fi
      fi     
  fi
    if [ "${LINE[19]}" = "Bol" ] 
    then
      if [ "${LINE[21]}" = "Rood/groen" ] ; then
        if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_Sphere_Red_Green_Beacon" ;fi
        if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_Sphere_Red_Green_Buoy_Small" ;fi
      fi     
  fi
  if [ "${LINE[19]}" = "2 Bollen" ] 
    then
        if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_Isol_Beacon" ;fi
        if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_Isol_Buoy_Small" ;fi 
    fi 
  if [ "${LINE[19]}" = "2 Kegels, punten naar beneden" ] 
    then
      if [ "${LINE[13]}" = "Pilaar" ] ; then TOPMARK="Top_South_Buoy" ;fi
      if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_South_Beacon" ;fi
      if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_South_Buoy_Small" ;fi
  fi
  if [ "${LINE[19]}" = "2 Kegels punten van elkaar af" ] 
    then
      if [ "${LINE[13]}" = "Pilaar" ] ; then TOPMARK="Top_East_Buoy" ;fi
        if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_East_Beacon" ;fi
        if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_East_Buoy_Small" ;fi   
  fi
  if [ "${LINE[19]}" = "2 Kegels, punten naar elkaar" ] 
    then
      if [ "${LINE[13]}" = "Pilaar" ] ; then TOPMARK="Top_West_Buoy" ;fi
        if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_West_Beacon" ;fi
        if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_West_Buoy_Small" ;fi    
  fi
  if [ "${LINE[19]}" = "2 Kegels, punten naar boven" ] 
    then
      if [ "${LINE[13]}" = "Pilaar" ] ; then TOPMARK="Top_North_Buoy" ;fi
        if [ "${LINE[13]}" = "spar" ] ; then TOPMARK="Top_North_Beacon" ;fi
        if [ "${LINE[13]}" = "stomp" ] ; then TOPMARK="Top_North_Buoy_Small" ;fi     
  fi
  
#### Lights ################ 

  if [ "${LINE[25]}" != "Niet toegewezen" ] 
    then
      if [ "${LINE[31]}" = "Wit" ] ; then LIGHT="Light_White_120" ; fi
      if [ "${LINE[31]}" = "Groen" ] ; then LIGHT="Light_Green_120" ;fi
      if [ "${LINE[31]}" = "Rood" ] ; then LIGHT="Light_Red_120" ;fi
      if [ "${LINE[31]}" = "Geel" ] ; then LIGHT="Light_White_120" ; fi
    ### set char text
      if [ "${LINE[25]}" = "very quick-flash plus long- fl" ] ; then LINE[25]="VQ+LFl" ; fi
      LIGHT_TEXT="$( cut -d '(' -f1 <<< "${LINE[25]}" )"
      
      if [ "${LINE[27]}" != "Niet toegewezen" ] ; then LIGHT_TEXT=$LIGHT_TEXT${LINE[27]}; fi
      
      if [ "${LINE[31]}" = "Wit" ] ; then COLOR="W " ; fi
      if [ "${LINE[31]}" = "Rood" ] ; then COLOR="R " ; fi
      if [ "${LINE[31]}" = "Groen" ] ; then COLOR="G " ; fi
      if [ "${LINE[31]}" = "Geel" ] ; then COLOR="Y " ; fi
      LIGHT_TEXT=$LIGHT_TEXT$COLOR
      if [ "${LINE[28]}" != "#" ] ; then LIGHT_TEXT=$LIGHT_TEXT"${LINE[28]}""s" ; fi
    fi

  
#### Write to File ####
if [ `expr "${LINE[34]}" '<' "$LAT_MAX1"` -gt 0 ] ; then
  if [ `expr "${LINE[34]}" '>' "$LAT_MIN1"` -gt 0 ] ; then
    if [ `expr "${LINE[33]}" '<' "$LON_MAX1"` -gt 0 ] ; then
      if [ `expr "${LINE[33]}" '>' "$LON_MIN1"` -gt 0 ]
      then
	echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE1
	echo "  <type>WPT</type>" >> $FILE1
	if [ $ShowLightChar = 1 ] ; then
	  echo "  <name>""${LINE[2]}"  >> $FILE1
	  echo $LIGHT_TEXT"</name>" >> $FILE1
	else
	  echo "  <name>""${LINE[2]}""</name>" >> $FILE1
	fi
	echo "  <sym>"$SYMBOL"</sym>" >> $FILE1
	echo "</wpt>" >> $FILE1
	if [ "$TOPMARK" != "" ] ; then
	  echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE1
	  echo "  <sym>"$TOPMARK"</sym>" >> $FILE1
	  echo "</wpt>" >> $FILE1
	fi
	if [ "$LIGHT" != "" ] ; then
	  echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE1
	  echo "  <sym>"$LIGHT"</sym>" >> $FILE1
	  echo "</wpt>" >> $FILE1
	fi
      fi
    fi
  fi
fi

if [ `expr "${LINE[34]}" '<' "$LAT_MAX2"` -gt 0 ] ; then
  if [ `expr "${LINE[34]}" '>' "$LAT_MIN2"` -gt 0 ] ; then
    if [ `expr "${LINE[33]}" '<' "$LON_MAX2"` -gt 0 ] ; then
      if [ `expr "${LINE[33]}" '>' "$LON_MIN2"` -gt 0 ]
      then
	echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE2
	echo "  <type>WPT</type>" >> $FILE2
	if [ $ShowLightChar = 1 ] ; then
	  echo "  <name>""${LINE[2]}"  >> $FILE2
	  echo $LIGHT_TEXT"</name>" >> $FILE2
	else
	  echo "  <name>""${LINE[2]}""</name>" >> $FILE2
	fi
	echo "  <sym>"$SYMBOL"</sym>" >> $FILE2
	echo "</wpt>" >> $FILE2
	if [ "$TOPMARK" != "" ] ; then
	  echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE2
	  echo "  <sym>"$TOPMARK"</sym>" >> $FILE2
	  echo "</wpt>" >> $FILE2
	fi
	if [ "$LIGHT" != "" ] ; then
	  echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE2
	  echo "  <sym>"$LIGHT"</sym>" >> $FILE2
	  echo "</wpt>" >> $FILE2
	fi
      fi
    fi
  fi
fi

if [ `expr "${LINE[34]}" '<' "$LAT_MAX3"` -gt 0 ] ; then
  if [ `expr "${LINE[34]}" '>' "$LAT_MIN3"` -gt 0 ] ; then
    if [ `expr "${LINE[33]}" '<' "$LON_MAX3"` -gt 0 ] ; then
      if [ `expr "${LINE[33]}" '>' "$LON_MIN3"` -gt 0 ]
      then
	echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE3
	echo "  <type>WPT</type>" >> $FILE3
	if [ $ShowLightChar = 1 ] ; then
	  echo "  <name>""${LINE[2]}"  >> $FILE3
	  echo $LIGHT_TEXT"</name>" >> $FILE3
	else
	  echo "  <name>""${LINE[2]}""</name>" >> $FILE3
	fi
	echo "  <sym>"$SYMBOL"</sym>" >> $FILE3
	echo "</wpt>" >> $FILE3
	if [ "$TOPMARK" != "" ] ; then
	  echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE3
	  echo "  <sym>"$TOPMARK"</sym>" >> $FILE3
	  echo "</wpt>" >> $FILE3
	fi
	if [ "$LIGHT" != "" ] ; then
	  echo "<wpt lat=\"${LINE[34]}\" lon=\"${LINE[33]}\">" >> $FILE3
	  echo "  <sym>"$LIGHT"</sym>" >> $FILE3
	  echo "</wpt>" >> $FILE3
	fi
      fi
    fi
  fi
fi
echo "${LINE[2]}", "${LINE[34]}", "${LINE[33]}" 
done < $1

echo "</gpx>"  >> $FILE1
echo "</gpx>"  >> $FILE2
echo "</gpx>"  >> $FILE3
