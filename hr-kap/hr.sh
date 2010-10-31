#! /bin/sh
# nohal - 2010-10-26

# To run this you need: wget, libbsb, ImageMagic, tar, zip and bzip2
# Configure a bit
OUTPUTDIR="../docs/adriatic-weather"
WORKINGDIR="/var/www/virtualhosts/opencpn.xtr.cz/HR-kap"

# And now do the work
cd $WORKINGDIR

HRKap(){
convert $1.gif -font courier -fill red  -gravity SouthEast -pointsize 10 -annotate +3+18 'OpenCPN' $2.gif
convert $2.gif -colors 127 $2.tif
tif2bsb -c 127 $3.hd $2.tif $2.kap
}

Dnld(){
wget http://prognoza.hr/nauticari/$1_$2_03.gif
wget http://prognoza.hr/nauticari/$1_$2_06.gif
wget http://prognoza.hr/nauticari/$1_$2_09.gif
wget http://prognoza.hr/nauticari/$1_$2_12.gif
wget http://prognoza.hr/nauticari/$1_$2_15.gif
wget http://prognoza.hr/nauticari/$1_$2_18.gif
wget http://prognoza.hr/nauticari/$1_$2_21.gif
wget http://prognoza.hr/nauticari/$1_$2_24.gif
wget http://prognoza.hr/nauticari/$1_$2_27.gif
wget http://prognoza.hr/nauticari/$1_$2_30.gif
wget http://prognoza.hr/nauticari/$1_$2_33.gif
wget http://prognoza.hr/nauticari/$1_$2_36.gif
wget http://prognoza.hr/nauticari/$1_$2_39.gif
wget http://prognoza.hr/nauticari/$1_$2_42.gif
wget http://prognoza.hr/nauticari/$1_$2_45.gif
wget http://prognoza.hr/nauticari/$1_$2_48.gif
wget http://prognoza.hr/nauticari/$1_$2_51.gif
wget http://prognoza.hr/nauticari/$1_$2_54.gif
wget http://prognoza.hr/nauticari/$1_$2_57.gif
wget http://prognoza.hr/nauticari/$1_$2_60.gif
wget http://prognoza.hr/nauticari/$1_$2_63.gif
wget http://prognoza.hr/nauticari/$1_$2_66.gif
wget http://prognoza.hr/nauticari/$1_$2_69.gif
wget http://prognoza.hr/nauticari/$1_$2_72.gif
}

HRKapsType(){
HRKap $1_$2_03 $1_$2_03 $2
HRKap $1_$2_06 $1_$2_06 $2
HRKap $1_$2_09 $1_$2_09 $2
HRKap $1_$2_12 $1_$2_12 $2
HRKap $1_$2_15 $1_$2_15 $2
HRKap $1_$2_18 $1_$2_18 $2
HRKap $1_$2_21 $1_$2_21 $2
HRKap $1_$2_24 $1_$2_24 $2
HRKap $1_$2_27 $1_$2_27 $2
HRKap $1_$2_30 $1_$2_30 $2
HRKap $1_$2_33 $1_$2_33 $2
HRKap $1_$2_36 $1_$2_36 $2
HRKap $1_$2_39 $1_$2_39 $2
HRKap $1_$2_42 $1_$2_42 $2
HRKap $1_$2_45 $1_$2_45 $2
HRKap $1_$2_48 $1_$2_48 $2
HRKap $1_$2_51 $1_$2_51 $2
HRKap $1_$2_54 $1_$2_54 $2
HRKap $1_$2_57 $1_$2_57 $2
HRKap $1_$2_60 $1_$2_60 $2
HRKap $1_$2_63 $1_$2_63 $2
HRKap $1_$2_66 $1_$2_66 $2
HRKap $1_$2_69 $1_$2_69 $2
HRKap $1_$2_72 $1_$2_72 $2
#Publish
mkdir -p $OUTPUTDIR/$2/$1
cp -f $1_$2_*.kap $OUTPUTDIR/$2/$1
tar c $1_$2_*.kap|bzip2 > $1_$2.tar.bz2
zip $1_$2.zip *.kap
mv $1_$2.tar.bz2 $OUTPUTDIR
mv $1_$2.zip $OUTPUTDIR
bzip2 $1_$2_*.kap
mv -f $1_$2_*.kap.bz2 $OUTPUTDIR/$2/$1
}

HRKaps(){
Dnld uv10 $1
Dnld uvgst $1
Dnld uk_naob $1
Dnld uk_obo $1
HRKapsType uv10 $1
HRKapsType uvgst $1
HRKapsType uk_naob $1
HRKapsType uk_obo $1
}

HRPart(){
HRKaps jadran
HRKaps sj_jadran
HRKaps sr_jadran
HRKaps ju_jadran
}

#Generate KAPs
HRPart

#Clean up directory
rm *.gif*
rm  *.tif*
rm *~

#Create complete archives
cd $OUTPUTDIR
zip -r all.zip . -i *.kap
tar cj  */*/*.kap > all.tar.bz2
