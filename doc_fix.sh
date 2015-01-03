#!/bin/bash

mv OpenCPN\ User\ Manual.html help_en_US.html
#Modify the internal image links to use images folder instead of "OpenCPN User Manual_files" and remove spaces from the hrefs to the anchors
sed -i -e "s/OpenCPN%20User%20Manual_files/images/g" help_en_US.html
sed -i -e "s/%20//g" help_en_US.html

#rename the anchor IDs not to contain spaces (I haven't seen any containing numbers, so look just for stuff containing letters and spaces)
grep -o "id=\"[a-zA-Z ]*\"" help_en_US.html | grep " " | awk '{ replacement=$0; gsub(" ", "", replacement);  system("sed -ibak -e \047s/"$0"/"replacement"/g\047 help_en_US.html");  }'
rm help_en_US.htmlbak

#Remove CSS classes
sed -i -e 's/ class="[a-z1-9\-\ ]*"//g' help_en_US.html
#Normalize the tables
sed -i -e 's/<table.*>/<table border="1" cellpadding="1" cellspacing="1">/g' help_en_US.html
#Insert CSS style
sed -i -e 's|<head>|<head>\n<style>\nhtml {\ncolor: #424242;\n}\n\nbody\n{\nbackground-color:#fcf8e9;\nfont-family: Tahoma,Verdana,Arial,Helvetica,sans-serif;\nfont-size: 75%;\nfont-weight: normal;\nline-height: 160%;\n}\n\na:link, a:visited {\ncolor: #3C6159;\n}\n</style>\n|g' help_en_US.html

mv OpenCPN\ User\ Manual_files images

#Assume the very big PNGs will compress better as JPG
BIGPNGS=`find images -name "*.png" -size +100k`
for f in $BIGPNGS
do
  F=`basename -s.png $f`
echo $F
  gm convert images/${F}.png images/${F}.jpg
  sed -i -e "s/images\/${F}\.png/images\/${F}\.jpg/g" help_en_US.html
  rm images/${F}.png
done

#Optimize the JPG images
find images -name "*.jp*" -exec sh -c "/opt/mozjpeg/bin/cjpeg -outfile {}.new {}; mv {}.new {}" \;
#Optimize the PNG images
find images -name "*.png" -exec gm convert {} -colors 32 {} \;
optipng -o7 images/*.png

rm images/print.html
