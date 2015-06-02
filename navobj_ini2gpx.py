#!/usr/bin/python

"""navobj_ini2gpx.py: Fixes the Selfmon configuration database"""

__author__ = "Pavel Kalian"
__copyright__ = "Copyright 2015, Pavel Kalian"
__credits__ = ["nohal"]
__license__ = "GPLv2"
__version__ = "1.0"
__maintainer__ = "Pavel Kalian"
__email__ = "pavel@kalian.cz"
__status__ = "Development"

"""
Input:  opencpn.ini from very old OpenCPN version

Output: GPX conatining the navobjects (waypoints)

TODO: 	Handle routes and tracks
		Handle the property flags
"""

import os
import sys
import re
from time import strftime

class Mark:
	RoutePointLat = -999.9 # 38.584000,20.797968
	RoutePointLon = -999.9
	RoutePointName = ""
	RoutePointDescription = ""
	RoutePointIcon = "diamond"
	RoutePointGUID = "" #385839-207979-1390570393-199
	RoutePointProp = "" #A,0,1,1,1
	RoutePointNameLocationOffsetX = 0 #-10,8
	RoutePointNameLocationOffsetY = 0

	def print_gpx(self):
		if self.RoutePointLat >= -90 and self.RoutePointLat <= 90 and self.RoutePointLon >= -180 and self.RoutePointLon <= 180:
			print "<wpt lat=\"{0}\" lon=\"{1}\">".format(self.RoutePointLat, self.RoutePointLon)
			print "<time>{0}</time>".format(strftime("%Y-%m-%dT%H:%M:%SZ"))
			print "<name>{0}</name>".format(self.RoutePointName)
			print "<desc>{0}</desc>".format(self.RoutePointDescription)
			print "<sym>{0}</sym>".format(self.RoutePointIcon)
			print "<type>WPT</type>"
			print "<extensions>"
			print "<opencpn:guid>{0}</opencpn:guid>".format(self.RoutePointGUID)
			print "<opencpn:viz_name>1</opencpn:viz_name>"
			print "</extensions>"
			print "</wpt>"


if len(sys.argv) != 2:
    print 'Usage: navobj_ini2gpx.py <opencpn.ini>'
    exit

iniinput = open(sys.argv[1])

print '<?xml version="1.0"?>'
print '<gpx version="1.1" creator="OpenCPN" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" xmlns:opencpn="http://www.opencpn.org">'

marks = False
current_wpt = None

for line in iniinput:
	if line.startswith("[Marks]"):
		marks = True
	if re.match("^\[Marks/MarkDefn.*\].*", line) != None:
		if current_wpt != None:
			current_wpt.print_gpx()
		current_wpt = Mark()
	data = re.match("^RoutePoint=([0-9]{1,}\.[0-9]{1,}),([0-9]{1,}\.[0-9]{1,})", line)
	if data != None:
		current_wpt.RoutePointLat = float(data.group(1))
		current_wpt.RoutePointLon = float(data.group(2))
	data = re.match("^RoutePointName=(.*)", line)
	if data != None:
		current_wpt.RoutePointName = data.group(1).strip()
	data = re.match("^RoutePointDescription=(.*)", line)
	if data != None:
		current_wpt.RoutePointDescription = data.group(1).strip()
	data = re.match("^RoutePointIcon=(.*)", line)
	if data != None:
		current_wpt.RoutePointIcon = data.group(1).strip()
	data = re.match("^RoutePointGUID=(.*)", line)
	if data != None:
		current_wpt.RoutePointGUID = data.group(1).strip()
	data = re.match("^RoutePointProp=(.*)", line)
	if data != None:
		current_wpt.RoutePointProp = data.group(1).strip()
	data = re.match("^RoutePointNameLocationOffset=(.{1,}),(.{1,})", line)
	if data != None:
		current_wpt.RoutePointNameLocationOffsetX = int(data.group(1))
		current_wpt.RoutePointNameLocationOffsetY = int(data.group(1))

print "</gpx>"
