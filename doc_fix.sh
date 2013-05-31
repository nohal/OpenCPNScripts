#!/bin/bash
#Modify the internal image links to use images folder instead of "OpenCPN User Manual_files" and remove spaces from the hrefs to the anchors

sed -e "s/OpenCPN%20User%20Manual_files/images/g" help_en_US.html | sed -e "s/%20//g" > tmp.html

mv tmp.html help_en_US.html

mv OpenCPN\ User\ Manual_files images

#rename the anchor IDs not to contain spaces (I haven't seen any containing numbers, so look just for stuff containing letters and spaces)

grep -o "id=\"[a-zA-Z ]*\"" help_en_US.html | grep " " | awk '{ replacement=$0; gsub(" ", "", replacement);  system("sed -ibak -e \047s/"$0"/"replacement"/g\047 help_en_US.html");  }'

rm help_en_US.htmlbak
