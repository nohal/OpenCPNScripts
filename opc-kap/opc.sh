#! /bin/sh
cd /var/www/virtualhosts/opencpn.xtr.cz/OPC-kap
# TH 100705
# To run this you need: wget, libbsb and ImageMagic,

# 96 h srfc fcst
wget http://www.opc.ncep.noaa.gov/shtml/pwam99bw.gif

# 96 h 500mb fcst
wget http://www.opc.ncep.noaa.gov/shtml/ppam50bw.gif

# 96 h wind wave
wget http://www.opc.ncep.noaa.gov/shtml/pjam98bw.gif

# 48 h srfc fcst
wget http://www.opc.ncep.noaa.gov/shtml/qdtm86bw.gif

# 48 h 500mb fcst
wget http://www.opc.ncep.noaa.gov/shtml/ppai51bw.gif

# 48 h wind wave
wget http://www.opc.ncep.noaa.gov/shtml/pjai99bw.gif

# Surface analysis E Atlantic
wget http://www.opc.ncep.noaa.gov/shtml/pyaa07bw.gif

# Surface analysis W Atlantic
wget http://www.opc.ncep.noaa.gov/shtml/pyaa08bw.gif

# OPCKap "filename from OPC" "local name for this file" " tif2bsb template/headerfile to use"

OPCKap(){
convert $1.gif -font courier -fill red  -gravity SouthEast -pointsize 10 -annotate +3+18 'OpenCPN' $2.gif
convert $2.gif -colors 127 $2.tif
tif2bsb -c 127 $3.hd $2.tif $2.kap
}

#Remove old forecasts
rm *.kap

OPCKap pwam99bw 96hsrfcst opc_10-90
OPCKap ppam50bw 96h500fcst opc_10-90
OPCKap pjam98bw 96hwwfcst opc_10-90
OPCKap qdtm86bw 48hsrfcst opc_10-90
OPCKap ppai51bw 48h500fcst opc_10-90
OPCKap pjai99bw 48hwwfcst opc_10-90
OPCKap pyaa07bw srfanal_E  opc_10-35
OPCKap pyaa08bw srfanal_W  opc_35-90

#Clean up directory
rm *.gif*
rm  *.tif*
rm *~

#Publishing

cp *.kap /var/www/virtualhosts/opencpn.xtr.cz/docs/opc/
bzip2 *.kap
mv *.kap.bz2 /var/www/virtualhosts/opencpn.xtr.cz/docs/opc/
cd /var/www/virtualhosts/opencpn.xtr.cz/docs/opc/
rm *.zip
rm *.tar.bz2
tar c *.kap|bzip2 > all.tar.bz2
zip all.zip *.kap
