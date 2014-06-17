# FG Atlas protocol: GPRMC/GPGGA to AIVDM stream converter
# using parts of encode/decode routines as published at 
#          http://softwaredevelopmentperestroika.wordpress.com/
# with some essential edits and necessary corrections and enhancements
# default usage corresponds to:
# python at2vdm.py -listen "127.0.0.1:5500" -forward "127.0.0.1:5600" -verbose 1 -loglevel 1 -logto "at2vdm.log" -aivdm_type 9 mmsi 111981199 -seconds 5 -static "vdmstatic.dat" -serial ""
# for options setting see below
# Python 3.3
# vers. 1.2
#    - process Type 1, 9, (0 for dry run - logging only)
#    - process GGA for altitude
#    - send out AIVDM every x seconds
#    - include a prologue of static messages
#    - output to UDP or COM

import bitstring
import re
import locale

import socket
import sys
import time
import os
import argparse
import math

#ais NMEA payload encoding
payloadencoding = {0:'0',1:'1',2:'2',3:'3',4:'4',5:'5',6:'6',7:'7',8:'8',9:'9',10:':',11:';',12:'<',13:'=',14:'>',15:'?',16:'@',17:'A',

18:'B',19:'C',20:'D',21:'E',22:'F',23:'G',24:'H',25:'I',26:'J',27:'K',28:'L',29:'M',30:'N',31:'O',32:'P',

33:'Q',34:'R',35:'S',36:'T',37:'U',38:'V',39:'W',40:'`',41:'a',42:'b',43:'c',44:'d',45:'e',46:'f',47:'g',

48:'h',49:'i',50:'j',51:'k',52:'l',53:'m',54:'n',55:'o',56:'p',57:'q',58:'r',59:'s',60:'t',61:'u',62:'v',63:'w'}

# create AIS-string decoding map
reverseencoding = dict()

for k,e in payloadencoding.items():
  reverseencoding[e] = k

def nmeaChecksum(s): # str -> two hex digits in str
  chkSum = 0
  subStr = s[1:len(s)]
  for e in range(len(subStr)):
    chkSum ^= ord((subStr[e]))
  hexstr = (str(hex(chkSum))[2:4]).upper()
  if len(hexstr) == 2:
    return hexstr
  else:
    return '0'+hexstr

# join NMEA pre- and postfix to payload string
def joinNMEAstrs(headerstr, payloadstr): #str -> str
  tempstr = headerstr + payloadstr + ',0'
  chksum = nmeaChecksum(tempstr)
  tempstr += '*'
  tempstr += chksum
  return tempstr

# encode bitstream to 6bit ascii string
def aisencode (aisstr): #BitString -> string
  l = 0
  r = 6 # six bit chunks
  aisnmea = []
  for i in range (0,28): #168 bits in 28 chunks of 6
    chunk1 = aisstr[l:r]
    char = str(chunk1.uint)
    intie = int(char)
    aisnmea.append(payloadencoding[intie])
    l += 6
    r +=6
  aisstr = ''.join(aisnmea)
  return aisstr

def bin6(x): # int -> 6 binary digits
  return ''.join(x & (1 << i) and '1' or '0' for i in range(5,-1,-1))

# convert vector of ints to bitstring
def intvec2bitstring(aisvec): #intvec -> Bitstring
  nmeanums = []
  for i in range(len(aisvec)):
    nmeanums.append(bin6(aisvec[i]))
  bitstrng = ''.join(nmeanums)
  return bitstrng

# decode AIS string to int vector
def aisdecode(aisstr): #string -> numvec
  numvec = []
  numstr = ''
  for i in aisstr:
    key = i
    code = reverseencoding[key]
    numvec.append(code)
  return numvec

# create a bitstring from an AIVDM map
def unpackvdm1(): #map -> bitstring
  bitstr =bitstring.BitString = vdmmap['type']
  bitstr.append(vdmmap['repeat'])
  bitstr.append(vdmmap['mmsi'])
  bitstr.append(vdmmap['status'])
  bitstr.append(vdmmap['turn'])
  bitstr.append(vdmmap['speed'])
  bitstr.append(vdmmap['accuracy'])
  bitstr.append(vdmmap['lon'])
  bitstr.append(vdmmap['lat'])
  bitstr.append(vdmmap['course'])
  bitstr.append(vdmmap['heading'])
  bitstr.append(vdmmap['second'])
  bitstr.append(vdmmap['maneuver'])
  bitstr.append(vdmmap['spare'])
  bitstr.append(vdmmap['raim'])
  bitstr.append(vdmmap['radio'])
  return bitstr

def unpackvdm9(): #map -> bitstring
  bitstr =bitstring.BitString = vdmmap['type']
  bitstr.append(vdmmap['repeat'])
  bitstr.append(vdmmap['mmsi'])
  bitstr.append(vdmmap['alt'])
  bitstr.append(vdmmap['speed'])
  bitstr.append(vdmmap['accuracy'])
  bitstr.append(vdmmap['lon'])
  bitstr.append(vdmmap['lat'])
  bitstr.append(vdmmap['course'])
  bitstr.append(vdmmap['second'])
  bitstr.append(vdmmap['regional'])
  bitstr.append(vdmmap['dte'])
  bitstr.append(vdmmap['spare'])
  bitstr.append(vdmmap['assigned'])
  bitstr.append(vdmmap['raim'])
  bitstr.append(vdmmap['radio'])
  return bitstr

##################################
#
# set up options
#
##################################

parser = argparse.ArgumentParser(description='Convert $GPRMC/GPGGA NMEA string to !AIVDM type 1 or 9.')
parser.add_argument("-listen", dest='listen', nargs='?', const="192.168.2.1:5500", default="127.0.0.1:5500")
parser.add_argument("-forward", dest='forward',  nargs='?', const="192.168.2.1:5600", default="127.0.0.1:5600")
parser.add_argument("-verbose", dest='verbose', nargs='?', type=int, const=3, default=1)
parser.add_argument("-loglevel", dest='loglevel',nargs='?', type=int, const=3, default=0)
parser.add_argument("-logto", dest='logto', nargs='?', const="rmc2vdm.log", default="rmc2vdm.log")
parser.add_argument("-aivdm_type", dest='aivdm_type', nargs='?', type=int, const=1, default=9)
parser.add_argument("-mmsi", dest='mmsi', nargs='?', type=int, const=111981199, default=111981199)
parser.add_argument("-seconds", dest='seconds', nargs='?', type=int, const=5, default=2)
parser.add_argument("-static", dest='static', nargs='?', const="vdmstatic.dat", default="")
parser.add_argument("-serial", dest='serial', nargs='?', const="com4", default="")

opts = parser.parse_args()
listen_opt=re.split(':',opts.listen)
listen_host=listen_opt[0]
listen_port=locale.atoi(listen_opt[1])
forward_opt=re.split(':',opts.forward)
forward_host = forward_opt[0]
forward_port = locale.atoi(forward_opt[1])
verbose = opts.verbose
loglevel = opts.loglevel
logto = opts.logto
aivdm_type = opts.aivdm_type # type 1 is Class A position report, type 9 is SAR aircraft position report
mmsi = opts.mmsi # 303981000 USS Nimitz 330x75x12m
seconds = opts.seconds
static = opts.static
serial=opts.serial
altitude = 4095 # assumed if no GGA input

if (static != ""):
   staticfile = open( static, 'r')

if (verbose >= 1 ):
  print("listening on " + listen_host+":" + str(listen_port) + "\n" + "verbosity: " + str(verbose))
  print("VDM type: " + str(aivdm_type))

if (loglevel > 0): logfile = open( logto, 'w', buffering=1)

if (loglevel >= 1):
  logfile.write("listening on " + listen_host + ":" + str(listen_port) + "\n" + "loglevel: " + str(loglevel) +"\n")
  logfile.write("logging to file: " + logto +"\n")
  print("loglevel: " + str(loglevel))
  print("logging to file: " + logto)

# Set up UDP server and client

# Listen on one port

UDPSock = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)

listen_addr = (listen_host, listen_port)

UDPSock.bind(listen_addr)


# Forward to another port maybe on another host or to a COM port
                    
if (serial == ""):
  UDPSockout = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)

  forward_addr = (forward_host, forward_port)

  if (verbose >= 1):  print("forwarding to " + forward_host + ":" + str(forward_port))

  if (loglevel >= 1):  logfile.write("forwarding to " + forward_host + ":" + str(forward_port) + "\n")
                    
else:
  comport = open( serial, 'w', buffering=1)

  if (verbose >= 1):  print("forwarding to " + serial)

  if (loglevel >= 1):  logfile.write("forwarding to " + serial + "\n")

if (verbose >= 1):  print("including static data :" + static)

if (loglevel >= 1):  logfile.write("including static data :" + static + "\n")

vdmmap = dict()
lastsec = -1
aivdm = ""

static = "vdmstatic.dat"

if (os.path.exists(static)):
   staticfile = open( static, 'r')
   aivdm = staticfile.read()
   while (aivdm != ""):
     if (serial == ""): UDPSockout.sendto(aivdm.encode(),forward_addr)
     else: comport.write(aivdm+'\n')
     if (verbose >=1 ):
       print(aivdm)
     aivdm = staticfile.read()
     
while True:
  data,addr = UDPSock.recvfrom(1024)
  if (verbose >=3 ):  print(data.decode())

  for stmt in data.decode().splitlines():
    if stmt.startswith('$GPRMC') or stmt.startswith('$GPGGA') :
      rmc = stmt

      if (verbose >= 2): print(rmc, "\n")

      if (loglevel >= 2): logfile.write(rmc + "\n")

# sample input: '$GPRMC,200510,A,3748.001,N,12236.011,W,000.0,196.0,0505114,0.000,E*55'
#               '$GPGGA,201828,3748.001,N,12236.011,W,1,,,1751,F,,,,*06'

      splitrmc = re.split(',', rmc)
      if stmt.startswith('$GPGGA') :
        altitude = int(locale.atof(splitrmc[9]))
        if splitrmc[10]=='F': altitude = int(altitude * 0.3048) # feet to meters

        if (verbose >=3):
          print('altitude = ', altitude)
        if (loglevel >= 3 ):
          logfile.write('altitude = ' + locale.str(altitude) + "\n")
        continue

      tt = int(locale.atof(splitrmc[1]))
      g_sec = int(tt%100 + ((tt/100)%100)*60 + ((tt/10000)%100)*3600)

      if (lastsec < 0): lastsec = g_sec

      diffsec = g_sec - lastsec
      if ( diffsec <= seconds ): continue

      lastsec = g_sec
      g_sec = g_sec%60

      s_lat = re.split('\.', splitrmc[3])
      g_lat = locale.atoi(s_lat[0])//100 + (locale.atoi(s_lat[0])%100)/60 + (locale.atoi(s_lat[1])/60)/pow(10, len(s_lat[1]))
      if splitrmc[4]=='S' : g_lat = -g_lat
      s_lon = re.split('\.', splitrmc[5])
      g_lon = (locale.atoi(s_lon[0])//100) + (locale.atoi(s_lon[0])%100)/60 + (locale.atoi(s_lon[1])/60)/pow(10, len(s_lon[1]))
      if splitrmc[6]=='W' : g_lon = -g_lon
      g_sog = locale.atof(splitrmc[7])
      g_sog = abs(g_sog) # bug in FG
      g_cog = locale.atof(splitrmc[8])

      if (verbose >=3 ):
        print('lat = ', g_lat)
        print('lon = ', g_lon)
        print('sog = ', g_sog)
        print('cog = ', g_cog)

      if (loglevel >=3 ):
        logfile.write('lat = ' + locale.str(g_lat) + "\n")
        logfile.write('lon = ' + locale.str(g_lon) + "\n")
        logfile.write('sog = ' + locale.str(g_sog) + "\n")
        logfile.write('cog = ' + locale.str(g_cog) + "\n")

      if (aivdm_type <= 0): continue   # just decode RMC, no VDM desired

# set up AIS data from available GPS input, assume defaults otherwise

      a_repeat = 0
      a_mmsi = mmsi
      a_acc = 1
      a_lon = int(g_lon * 600000)
      a_lat = int(g_lat * 600000)

      if (g_cog < 0.0):
        a_cog = round(g_cog + 360) * 10
      else:
        a_cog = round(g_cog) *10

      if (altitude > 4095):
        altitude = 4094

      if (altitude < 0):
        altitude = 0

      if (verbose >=3 ):
        print('a_cog = ', a_cog)

      if (loglevel >=3 ):
        logfile.write('a_cog = ' + locale.str(a_cog) + "\n")

      a_secs = g_sec
      a_spare = 0
      a_raim = 0
      a_radio = 0

      vdmmap.clear()

      if (aivdm_type == 1):
        a_type = 1
        a_stat = 0
        a_sog = round(g_sog * 10)
        a_hdg = round(a_cog / 10)

        a_rot = 128 # leave undefined

        a_mvr = 0
        vdmmap['type'] = bitstring.BitStream(uint=a_type,length=6)
        vdmmap['repeat'] = bitstring.BitStream(uint=a_repeat,length=2)
        vdmmap['mmsi'] = bitstring.BitStream(uint=a_mmsi,length=30)
        vdmmap['status'] = bitstring.BitStream(uint=a_stat,length=4)
        vdmmap['turn'] = bitstring.BitStream(uint=a_rot,length=8)
        vdmmap['speed'] = bitstring.BitStream(uint=a_sog,length=10)
        vdmmap['accuracy'] = bitstring.BitStream(uint=a_acc,length=1)
        vdmmap['lon'] = bitstring.BitStream(int=a_lon,length=28)
        vdmmap['lat'] = bitstring.BitStream(int=a_lat,length=27)
        vdmmap['course'] = bitstring.BitStream(uint=a_cog,length=12)
        vdmmap['heading'] = bitstring.BitStream(uint=a_hdg,length=9)
        vdmmap['second'] = bitstring.BitStream(uint=a_secs,length=6)
        vdmmap['maneuver'] = bitstring.BitStream(uint=a_mvr,length=2)
        vdmmap['spare'] = bitstring.BitStream(uint=a_spare,length=3)
        vdmmap['raim'] = bitstring.BitStream(uint=a_raim,length=1)
        vdmmap['radio'] = bitstring.BitStream(uint=a_radio,length=19)
        newstream = unpackvdm1()
        aivdm = joinNMEAstrs('!AIVDM,1,1,,A,', aisencode(newstream))

      if (aivdm_type == 9):
        a_type = 9
        a_alt = altitude
        a_sog = int(g_sog)
        a_reg = 0
        a_dte = 1 # default value ("not ready")
        a_assgn = 0
        vdmmap['type'] = bitstring.BitStream(uint=a_type,length=6)
        vdmmap['repeat'] = bitstring.BitStream(uint=a_repeat,length=2)
        vdmmap['mmsi'] = bitstring.BitStream(uint=a_mmsi,length=30)
        vdmmap['alt'] = bitstring.BitStream(uint=a_alt,length=12)
        vdmmap['speed'] = bitstring.BitStream(uint=a_sog,length=10)
        vdmmap['accuracy'] = bitstring.BitStream(uint=a_acc,length=1)
        vdmmap['lon'] = bitstring.BitStream(int=a_lon,length=28)
        vdmmap['lat'] = bitstring.BitStream(int=a_lat,length=27)
        vdmmap['course'] = bitstring.BitStream(uint=a_cog,length=12)
        vdmmap['second'] = bitstring.BitStream(uint=a_secs,length=6)
        vdmmap['regional'] = bitstring.BitStream(uint=a_reg,length=8)
        vdmmap['dte'] = bitstring.BitStream(uint=a_dte,length=1)
        vdmmap['spare'] = bitstring.BitStream(uint=a_spare,length=3)
        vdmmap['assigned'] = bitstring.BitStream(uint=a_assgn,length=1)
        vdmmap['raim'] = bitstring.BitStream(uint=a_raim,length=1)
        vdmmap['radio'] = bitstring.BitStream(uint=a_radio,length=19)
        newstream = unpackvdm9()
        aivdm = joinNMEAstrs('!AIVDM,1,1,,A,', aisencode(newstream))

      if (verbose > 0): print(aivdm, "\n")

      if (loglevel > 0): logfile.write(aivdm + "\n")

      if (aivdm_type > 0):
        if (serial == ""): UDPSockout.sendto(aivdm.encode(),forward_addr)
        else: comport.write(aivdm+'\n')

