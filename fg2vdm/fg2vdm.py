# FG AIVDM protocol output to AIVDM stream converter
# using parts of encode/decode routines as published at 
#          http://softwaredevelopmentperestroika.wordpress.com/
# with some essential edits and necessary corrections and enhancements
# default usage corresponds to:
# python fg2vdm.py -listen "127.0.0.1:5501" -forward "127.0.0.1:5600" -verbose 1 -loglevel 1 -logto "fg2vdm.log" -seconds 5 -static "vdmstatic.dat" -vessels "vessels.dat" -seconds 5 -eta "current"
# for options setting see below
# Python 3.3
# vers. 0.8
#
#    - include a prologue of static messages
#    - include static vessel data from csv database
#    - use altitude for aircraft targets
#    - prepare dynamically Type 5 messages for AI aircraft
#    - output AIVDM package only every x seconds
#    - use current date/time or undefined for ETA

import bitstring
import re
import locale

import socket
import sys
import time
import os
import argparse
import math
from datetime import *
import time

#ais NMEA payload encoding
payloadencoding = {0:'0',1:'1',2:'2',3:'3',4:'4',5:'5',6:'6',7:'7',8:'8',9:'9',10:':',11:';',12:'<',13:'=',14:'>',15:'?',16:'@',17:'A',

18:'B',19:'C',20:'D',21:'E',22:'F',23:'G',24:'H',25:'I',26:'J',27:'K',28:'L',29:'M',30:'N',31:'O',32:'P',

33:'Q',34:'R',35:'S',36:'T',37:'U',38:'V',39:'W',40:'`',41:'a',42:'b',43:'c',44:'d',45:'e',46:'f',47:'g',

48:'h',49:'i',50:'j',51:'k',52:'l',53:'m',54:'n',55:'o',56:'p',57:'q',58:'r',59:'s',60:'t',61:'u',62:'v',63:'w'}

# create AIS-string decoding map
reverseencoding = dict()

for k,e in payloadencoding.items():
  reverseencoding[e] = k

#ais 6-bit ASCII encoding
asciiencoding = {0:'@',1:'A',2:'B',3:'C',4:'D',5:'E',6:'F',7:'G',8:'H',9:'I',10:'J',11:'K',12:'L',13:'M',14:'N',15:'O',16:'P',17:'Q',

18:'R',19:'S',20:'T',21:'U',22:'V',23:'W',24:'X',25:'Y',26:'Z',27:'[',28:'\\',29:']',30:'^',31:'_',32:' ',

33:'!',34:'"',35:'#',36:'$',37:'%',38:'&',39:'\'',40:'(',41:')',42:'*',43:'+',44:',',45:'-',46:'.',47:'/',

48:'0',49:'1',50:'2',51:'3',52:'4',53:'5',54:'6',55:'7',56:'8',57:'9',58:':',59:';',60:'<',61:'=',62:'>',63:'?'}

# create 6-bit ASCII decoding map
reverseascii = dict()

for k,e in asciiencoding.items():
  reverseascii[e] = k

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
def joinNMEAstrs(headerstr, payloadstr, trailstr): #str -> str
  tempstr = headerstr + payloadstr + trailstr
  chksum = nmeaChecksum(tempstr)
  tempstr += '*'
  tempstr += chksum
  return tempstr

# encode bitstream to 6bit ascii string
def aisencode (aisstr, a, b): #BitString -> string, starting at chunk a, b chunks long
  l = a * 6
  r = l + 6 # six bit chunks
  aisnmea = []
  for i in range ( a, b ): # bits in chunks of 6
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
    code = reverseascii[key.upper()]
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

def unpackvdm5(): #map -> bitstring
  bitstr =bitstring.BitString = vdmmap['type']
  bitstr.append(vdmmap['repeat'])
  bitstr.append(vdmmap['mmsi'])
  bitstr.append(vdmmap['versn'])
  bitstr.append(vdmmap['imo'])
  bitstr.append(vdmmap['callsign'])
  bitstr.append(vdmmap['name'])
  bitstr.append(vdmmap['shiptype'])
  bitstr.append(vdmmap['to_bow'])
  bitstr.append(vdmmap['to_stern'])
  bitstr.append(vdmmap['to_port'])
  bitstr.append(vdmmap['to_stbd'])
  bitstr.append(vdmmap['fixtype'])
  bitstr.append(vdmmap['eta_month'])
  bitstr.append(vdmmap['eta_day'])
  bitstr.append(vdmmap['eta_hour'])
  bitstr.append(vdmmap['eta_minute'])
  bitstr.append(vdmmap['draught'])
  bitstr.append(vdmmap['destination'])
  bitstr.append(vdmmap['dte'])
  bitstr.append(vdmmap['spare'])
  bitstr.append(vdmmap['filler'])
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

def addmmsi(mmsi,id):
  if (id == ''): return

  mmsimap[id] = mmsi
  
  if (verbose >= 1):  print("adding MMSI: ", mmsi, id)

  if (loglevel >= 1):  logfile.write("adding MMSI: " + locale.str(mmsi) + " " + id + "\n")



##################################
#
# set up options
#
##################################

parser = argparse.ArgumentParser(description='Convert FG aivdm_vi protocol to !AIVDM sentences')
parser.add_argument("-listen", dest='listen', nargs='?', const="192.168.2.1:5501", default="192.168.2.1:5501")
parser.add_argument("-forward", dest='forward',  nargs='?', const="192.168.2.1:5600", default="127.0.0.1:5600")
parser.add_argument("-verbose", dest='verbose', nargs='?', type=int, const=3, default=1)
parser.add_argument("-loglevel", dest='loglevel',nargs='?', type=int, const=3, default=0)
parser.add_argument("-logto", dest='logto', nargs='?', const="fg2vdm.log", default="fg2vdm.log")
parser.add_argument("-seconds", dest='seconds', nargs='?', type=int, const=2, default=5)
parser.add_argument("-static", dest='static', nargs='?', const="vdmstatic.dat", default="")
parser.add_argument("-vessels", dest='vessels', nargs='?', const="vessels.dat", default="vessels.dat")
parser.add_argument("-serial", dest='serial', nargs='?', const="com2", default="")
parser.add_argument("-eta", dest='eta', nargs='?', const="undefined", default="current")


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
seconds = opts.seconds
static = opts.static
vessels = opts.vessels
serial = opts.serial
eta = opts.eta
altitude = 4095 # assumed if no GGA input
mmsipool = 303980100

if (verbose >= 1 ):
  print("listening on " + listen_host+":" + str(listen_port) + "\n" + "verbosity: " + str(verbose))

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

aivdm = ""

# include a file of any NMEA data from static file

if (os.path.exists(static)):
  if (verbose >= 1):
    print("including static file :" + static)
  if (loglevel >= 1):
    logfile.write("including static file :" + static + "\n")
  staticfile = open( static, 'r')
  aivdm = staticfile.readline().strip('\n')
  while (aivdm != ""):
    if (verbose >=1 ):
      print(aivdm)
                    
    if (serial == ""): UDPSockout.sendto(aivdm.encode(),forward_addr)
    else: comport.write(aivdm+'\n')

    aivdm = staticfile.readline().strip('\n')

# prepare AIVDM Type 5 sentences from a csv database as per the scenarios

# csv file format:
# NAME,DESTINATION,CALLSIGN,SIGN,MMSI,IMO,TYPE,TO_BOW,TO_STERN,TO_PORT,TO_STBD,DRAUGHT,SCENARIO
# example
#      0      1      2      3         4 5  6   7   8  9 10 11          12
# Nimitz,HAWAII,CVN-68,CVN-68,303981000,0,35,200,100,48,12,12,Nimitz_demo
#

mmsimap = dict()

if (os.path.exists(vessels)):
  if (verbose >= 1):
    print("including vessel data :" + vessels)
  if (loglevel >= 1):
    logfile.write("including vessel data :" + vessels + "\n")
  staticfile = open( vessels, 'r')
  vdmcsv = staticfile.readline().strip('\n')
  while (vdmcsv != ""):
     if (verbose >=1 ):
       print(vdmcsv)

     vdmmap = dict()
     splitvdm = re.split(',', vdmcsv)
     a_type = 5
     a_repeat = 1
     a_mmsi = locale.atoi(splitvdm[4])
     a_versn = 0
     a_imo = locale.atoi(splitvdm[5])
     a_callsign = (splitvdm[2]+'       ')[0:7] # 7 char length
     addmmsi(a_mmsi,splitvdm[2])
     addmmsi(a_mmsi,splitvdm[3])
     a_name = (splitvdm[0]+'                    ')[0:20] # 20 char length
     addmmsi(a_mmsi,splitvdm[0])
     a_shiptype = locale.atoi(splitvdm[6])
     a_to_bow = locale.atoi(splitvdm[7])
     a_to_stern = locale.atoi(splitvdm[8])
     a_to_port = locale.atoi(splitvdm[9])
     a_to_stbd = locale.atoi(splitvdm[10])
     a_fixtype = 1
     
     timestamp = datetime.now()
     if eta == "current" : a_eta_month = timestamp.month
     else: a_eta_month = 0
     
     if eta == "current" : a_eta_day = timestamp.day
     else: a_eta_day = 0
     
     if eta == "current" : a_eta_hour = timestamp.hour
     else: a_eta_hour = 24

     if eta == "current" : a_eta_minute = timestamp.minute
     else: a_eta_minute = 60
     
     a_draught = locale.atoi(splitvdm[11])*10 # * 0.1 m
     a_destination = splitvdm[1]
     if (a_destination == ''): a_destination = splitvdm[12]

     if (a_destination == ''): a_destination = 'FG DEMO'

     a_destination = (a_destination+'                    ')[0:20]

     a_dte = 1
     a_spare = 0
     vdmmap['type'] = bitstring.BitStream(uint=a_type,length=6)
     vdmmap['repeat'] = bitstring.BitStream(uint=a_repeat,length=2)
     vdmmap['mmsi'] = bitstring.BitStream(uint=a_mmsi,length=30)
     vdmmap['versn'] = bitstring.BitStream(uint=a_versn,length=2)
     vdmmap['imo'] = bitstring.BitStream(uint=a_imo,length=30)
     vdmmap['callsign'] = bitstring.pack('bin:42', intvec2bitstring(aisdecode(a_callsign))) # length=42
     vdmmap['name'] = bitstring.pack('bin:120', intvec2bitstring(aisdecode(a_name))) # length=120
     vdmmap['shiptype'] = bitstring.BitStream(uint=a_shiptype,length=8)
     vdmmap['to_bow'] = bitstring.BitStream(uint=a_to_bow,length=9)
     vdmmap['to_stern'] = bitstring.BitStream(uint=a_to_stern,length=9)
     vdmmap['to_port'] = bitstring.BitStream(uint=a_to_port,length=6)
     vdmmap['to_stbd'] = bitstring.BitStream(uint=a_to_stbd,length=6)
     vdmmap['fixtype'] = bitstring.BitStream(uint=a_fixtype,length=4)
     vdmmap['eta_month'] = bitstring.BitStream(uint=a_eta_month,length=4)
     vdmmap['eta_day'] = bitstring.BitStream(uint=a_eta_day,length=5)
     vdmmap['eta_hour'] = bitstring.BitStream(uint=a_eta_hour,length=5)
     vdmmap['eta_minute'] = bitstring.BitStream(uint=a_eta_minute,length=6)
     vdmmap['draught'] = bitstring.BitStream(uint=a_draught,length=8)
     vdmmap['destination'] = bitstring.pack('bin:120', intvec2bitstring(aisdecode(a_destination))) # length=120)
     vdmmap['dte'] = bitstring.BitStream(uint=a_dte,length=1)
     vdmmap['spare'] = bitstring.BitStream(uint=a_spare,length=1)
     vdmmap['filler'] = bitstring.BitStream(uint=0,length=2)

     newstream = unpackvdm5()

     aivdm = joinNMEAstrs('!AIVDM,2,1,,A,', aisencode(newstream, 0, 59), ',0')

     if (verbose > 0):
       print(aivdm, "\n")

     if (loglevel > 0):
       logfile.write(aivdm + "\n")
           
     if (serial == ""): UDPSockout.sendto(aivdm.encode(),forward_addr)
     else: comport.write(aivdm+'\n')

     aivdm = joinNMEAstrs('!AIVDM,2,2,,A,', aisencode(newstream, 59, 71), ',2')

     if (verbose > 0):
       print(aivdm, "\n")

     if (loglevel > 0):
       logfile.write(aivdm + "\n")
            
     if (serial == ""): UDPSockout.sendto(aivdm.encode(),forward_addr)
     else: comport.write(aivdm+'\n')

     vdmcsv = staticfile.readline().strip('\n')
     
vdmmap = dict()
lastsec = -1
aivdm = ""

while True:
  data,addr = UDPSock.recvfrom(4096)
  if (verbose >=3 ):  print(data.decode())
  
  n_sec = int(time.clock())

  if (lastsec >= 0):
    diffsec = n_sec - lastsec
    if ( diffsec <= seconds ): continue

  lastsec = n_sec
  g_sec = n_sec%60

  for stmt in data.decode().splitlines():
    if stmt.startswith('LAT=') or stmt.startswith(',LAT=') :
      rmc = stmt
      if (stmt[0]==','): rmc = stmt[1:]
      
      if (verbose >= 2): print(rmc, "\n")

      if (loglevel >= 2): logfile.write(rmc + "\n")

# sample input:

#LAT=37.78724,LON=-122.60585,ALT=0.00000,HDG=200.00000,SOG=10.00000,SIGN=CVN-68,CALLSIGN=,NAME=Nimitz,CARRIER
#,LAT=42.88725,LON=5.95369,ALT=0.00000,HDG=200.00000,SOG=10.00000,SIGN=CVN-69,CALLSIGN=,NAME=Eisenhower,CARRIER
#,LAT=35.95000,LON=-5.47662,ALT=0.00000,HDG=90.00032,SOG=14.00000,SIGN=CVN-70,CALLSIGN=Vinson,NAME=Vinson,CARRIER
#,LAT=35.95322,LON=-5.48134,ALT=0.00000,HDG=90.00000,SOG=14.00000,SIGN=,CALLSIGN=CG-48,NAME=Yorktown,ESCORT
#,LAT=35.94678,LON=-5.48134,ALT=0.00000,HDG=90.00000,SOG=14.00000,SIGN=,CALLSIGN=CG-57,NAME=Lake Champlain,ESCORT
#,LAT=0.00000,LON=0.00000,ALT=0.00000,HDG=0.00000,SOG=0.00000,CALLSIGN=,NAME=,SHIP
#,LAT=0.00000,LON=0.00000,ALT=0.00000,HDG=0.00000,SOG=0.00000,SIGN=,CALLSIGN=,NAME=,SHIP
#,LAT=36.98659,LON=-5.32735,ALT=31426.45313,HDG=201.59793,SOG=0.00000,SIGN=,CALLSIGN=AIRFRANS2458,NAME=,AIRCRAFT
#,LAT=35.49221,LON=-6.89006,ALT=31000.00000,HDG=14.09866,SOG=0.00000,SIGN=,CALLSIGN=MIDLAND448,NAME=,AIRCRAFT

      splitrmc = re.split(',', rmc)

      s_lat = re.split('=', splitrmc[0])
      g_lat = locale.atof(s_lat[1])
      
      s_lon = re.split('=', splitrmc[1])
      g_lon = locale.atof(s_lon[1])
      
      s_alt = re.split('=', splitrmc[2])
      g_alt = int(locale.atof(s_alt[1]) * 0.3048)
      
      if (g_alt > 4094): g_alt = 4094
      
      if (g_alt < 0 ): g_alt = 0
      
      s_sog = re.split('=', splitrmc[4])
      g_sog = locale.atof(s_sog[1])
      g_sog = abs(g_sog) # bug in FG
      
      s_cog = re.split('=', splitrmc[3])
      g_cog = locale.atof(s_cog[1])

      g_sign = (splitrmc[5].partition('='))[2]
      g_callsign = (splitrmc[6].partition('='))[2]
      g_name = ((splitrmc[7].partition('='))[2])
      g_aitype = splitrmc[8]

      if (verbose >=3 ):
        print('lat = ', g_lat)
        print('lon = ', g_lon)
        print('sog = ', g_sog)
        print('cog = ', g_cog)
        print('sign = ', g_sign)
        print('callsign = ', g_callsign)
        print('name = ', g_name)

      if (loglevel >=3 ):
        logfile.write('lat = ' + locale.str(g_lat) + "\n")
        logfile.write('lon = ' + locale.str(g_lon) + "\n")
        logfile.write('sog = ' + locale.str(g_sog) + "\n")
        logfile.write('cog = ' + locale.str(g_cog) + "\n")
        logfile.write('sign = ' + g_sign + "\n")
        logfile.write('callsign = ' + g_callsign + "\n")
        logfile.write('name = ' + g_name + "\n")

      a_mmsi = -1

      if (g_sign == '') and (g_callsign == '') and (g_name == ''): continue

      if (g_sign != '' and g_sign in mmsimap): a_mmsi = mmsimap[g_sign]

      if (g_callsign != '' and g_callsign in mmsimap): a_mmsi = mmsimap[g_callsign]

      if (g_name != '' and g_name in mmsimap): a_mmsi = mmsimap[g_name]

      if (a_mmsi < 0):
         a_mmsi = mmsipool
         mmsipool += 1
         addmmsi( a_mmsi, g_name)
         addmmsi( a_mmsi, g_callsign)
         addmmsi( a_mmsi, g_sign)
        
# produce a Type 5 message to assign a name to AI aircraft

         vdmmap = dict()
         a_type = 5
         a_repeat = 1
         a_versn = 0
         a_imo = 0
         a_callsign = '       ' # 7 char length
         a_name = (g_callsign+'                    ')[0:20] # 20 char length
         a_shiptype = 99
         a_to_bow = 0
         a_to_stern = 0
         a_to_port = 0
         a_to_stbd = 0
         a_fixtype = 1
         
         timestamp = datetime.now()
         if eta == "current" : a_eta_month = timestamp.month
         else: a_eta_month = 0
         
         if eta == "current" : a_eta_day = timestamp.day
         else: a_eta_day = 0
         
         if eta == "current" : a_eta_hour = timestamp.hour
         else: a_eta_hour = 24

         if eta == "current" : a_eta_minute = timestamp.minute
         else: a_eta_minute = 60
     
         a_draught = 0

         a_destination = 'FG DEMO'
         a_destination = (a_destination+'                    ')[0:20]

         a_dte = 1
         a_spare = 0
         vdmmap['type'] = bitstring.BitStream(uint=a_type,length=6)
         vdmmap['repeat'] = bitstring.BitStream(uint=a_repeat,length=2)
         vdmmap['mmsi'] = bitstring.BitStream(uint=a_mmsi,length=30)
         vdmmap['versn'] = bitstring.BitStream(uint=a_versn,length=2)
         vdmmap['imo'] = bitstring.BitStream(uint=a_imo,length=30)
         vdmmap['callsign'] = bitstring.pack('bin:42', intvec2bitstring(aisdecode(a_callsign))) # length=42
         vdmmap['name'] = bitstring.pack('bin:120', intvec2bitstring(aisdecode(a_name))) # length=120
         vdmmap['shiptype'] = bitstring.BitStream(uint=a_shiptype,length=8)
         vdmmap['to_bow'] = bitstring.BitStream(uint=a_to_bow,length=9)
         vdmmap['to_stern'] = bitstring.BitStream(uint=a_to_stern,length=9)
         vdmmap['to_port'] = bitstring.BitStream(uint=a_to_port,length=6)
         vdmmap['to_stbd'] = bitstring.BitStream(uint=a_to_stbd,length=6)
         vdmmap['fixtype'] = bitstring.BitStream(uint=a_fixtype,length=4)
         vdmmap['eta_month'] = bitstring.BitStream(uint=a_eta_month,length=4)
         vdmmap['eta_day'] = bitstring.BitStream(uint=a_eta_day,length=5)
         vdmmap['eta_hour'] = bitstring.BitStream(uint=a_eta_hour,length=5)
         vdmmap['eta_minute'] = bitstring.BitStream(uint=a_eta_minute,length=6)
         vdmmap['draught'] = bitstring.BitStream(uint=a_draught,length=8)
         vdmmap['destination'] = bitstring.pack('bin:120', intvec2bitstring(aisdecode(a_destination))) # length=120)
         vdmmap['dte'] = bitstring.BitStream(uint=a_dte,length=1)
         vdmmap['spare'] = bitstring.BitStream(uint=a_spare,length=1)
         vdmmap['filler'] = bitstring.BitStream(uint=0,length=2)

         newstream = unpackvdm5()

         aivdm = joinNMEAstrs('!AIVDM,2,1,,A,', aisencode(newstream, 0, 59), ',0')

         if (verbose > 0):
           print(aivdm, "\n")

         if (loglevel > 0):
           logfile.write(aivdm + "\n")
               
         if (serial == ""): UDPSockout.sendto(aivdm.encode(),forward_addr)
         else: comport.write(aivdm+'\n')

         aivdm = joinNMEAstrs('!AIVDM,2,2,,A,', aisencode(newstream, 59, 71), ',2')

         if (verbose > 0):
           print(aivdm, "\n")

         if (loglevel > 0):
           logfile.write(aivdm + "\n")
                
         if (serial == ""): UDPSockout.sendto(aivdm.encode(),forward_addr)
         else: comport.write(aivdm+'\n')

# --------------------------------------------------------------------

      if (g_aitype == 'AIRCRAFT' or g_name.startswith('Pedro')):
        aivdm_type = 9
        altitude = g_alt
      else: aivdm_type = 1

# set up AIS data from available GPS input, assume defaults otherwise

      a_repeat = 0
      a_acc = 1
      a_lon = int(g_lon * 600000)
      a_lat = int(g_lat * 600000)

      if (g_cog < 0.0):
        a_cog = round(g_cog + 360) * 10
      else:
        a_cog = round(g_cog) *10

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
        aivdm = joinNMEAstrs('!AIVDM,1,1,,A,', aisencode(newstream,0,28),',0')

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
        aivdm = joinNMEAstrs('!AIVDM,1,1,,A,', aisencode(newstream,0,28),',0')

      if (verbose > 0): print(aivdm, "\n")

      if (loglevel > 0): logfile.write(aivdm + "\n")
           
      if (serial == ""): UDPSockout.sendto(aivdm.encode(),forward_addr)
      else: comport.write(aivdm+'\n')


