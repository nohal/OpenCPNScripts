#!/usr/bin/ruby

#TH 2010-10-02,03
#2011-01-09, Ver 0.1.10 Handles spaces in filenames, print version, error/OK messages
#2011-02-14, Ver 0.1.11 Fixing space at beginning of kap name. NU changed to Chart123
#2011-08-05, Ver 0.2.00 Complete rewrite
#                       - Now using imgkap instead of tif2bsb. (This makes processing
#                         much faster, more flexible, and easier; eliminating all
#                         previous dependencies.)
#                       - More flexible file name handling, can now specify picture
#                         file name, map file name or base name (without extension)
#                         as first parameter
#                       - Automatically calculating scale for map based on Google zoom
#                         level at end of file name
#                       - Now correctly handling of map files with non-standard number
#                         of calibration points (for example from NoniMapView)
#                       - Improved consistency checking and error handling
#                       - Internal restructuring and clean-up of the script code
#2011-08-27, Ver 0.2.10 Implemented batch processing of multiple files
#2011-08-28, Ver 0.2.20 - Improved scale handling to allow different scales when
#                         multiple files are processed.
#                       - Better error handling; text output more clearly arranged
#                       - Added companion batch file to allow drag&drop of files
#                         on Windows
#2011-08-28, Ver 0.2.21 - Some dependency checking, improved Linux compatibility
#2011-10-16, Ver 0.2.22 Using scale in the range [500..10000000] from end of file
#                       name, if present

version = '0.2.22'

include Math

######################### Cusomizable variables ##########################

imgkap = ENV['MAP2KAP_IMGKAP']
unless imgkap   # environment variable not set
    if RUBY_PLATFORM =~ /mswin|mingw/
	    imgkap = "imgkap.exe"   # Windows
	else
	    imgkap = "imgkap"		# Other operating systems
	end
end

######################## Check runtime environment #######################

a = RUBY_VERSION.split('.') # Result: ["1", "8", "5"]
if a[0].to_i != 1 || a[1].to_i != 9 || a[2].to_i < 2
    STDERR.print "WARNING - Unsupported version #{RUBY_VERSION} of ruby interpreter installed.\n"
    STDERR.print "          (This script prefers ruby 1.9.2 and imgkap 1.11)\n"
end

######################### Function definitions ###########################


##########################################################################
# print out usage information
##########################################################################

def Usage
    puts "Usage: map2kap pic-or-map-file ... [scale [sounding-units [sounding-datum
               [lat-adj-to-wgs84-in-seconds long-adj-to-wgs84-in-seconds] ] ] ]\n
       For any picture file given, a valid Ozi V2 .map file must exist with
       the same base name as the picture file. For any map file name given,
       the picture file name is taken from its contents.
       Chart scale, if given on the command line, is used for all given files.
       If no scale is given on the command line, it is derived from a trailing
       numeric zoom level [6..20] of any given file name. If it cannot be de-
       termined that way for a given file, the user is prompted to input a
       scale for that file. (Note that the scale affects how charts are
       quilted in most navigation software.)
       Sounding-units, if not given, defaults to 'Meters'. If any parameter is
       left out, but others follow, put '0' (for scale) or 'unknown' (for
       sounding parameters) as a place holder.\n\n"
    puts "Dependencies: ruby and imgkap must be installed.\n"
	puts "              (Tested with ruby 1.9.2 and imgkap 1.11)\n"
end


##########################################################################
# declare class for file information
##########################################################################

FileInfo = Struct.new(:pathName, :baseName, :basePath, :extension, :scale)


##########################################################################
# Extract all relevant information from the given file/path name into
# a FileInfo struct
# - pathName:  the path portion, including a trailing path separator.
#              ("./" is simplified to "".)
# - baseName:  the base name (with leading path and trailing extension
#              chopped off)
# - basePath:  the path including the base name (but without extension)
# - extension: the type suffix (the part after the last '.'), converted
#              to uppercase
# - scale:     the default scale, based on a trailing numeric portion
#              of the base name,
#              -- directly used if in the range [500..10000000]
#              -- calculated from Google zoom level in the range [6..20]
#                 (Returned scale values in this case are between
#                 20 -> [1:]500 and 6 -> [1:]8192000).
#              -- nil if none of these is present in the file name
# Obviously, the basePath member is redundant; it exists only for
# convenience.
# Example: Given "C:\Images\Map-Google-15.jpg", the function will return
#          { pathName  = "C:\Images\";
#            baseName  = "Map-Google-15";
#            basePath  = "C:\Images\Map-Google-15";
#            extension = "JPG";
#            scale     = 16000 } 
##########################################################################

def GetFileInfo(filePath)
    # start off with an empty FileInfo (all members nil)
    fileInfo = FileInfo.new

    # separate extension from the rest
    a = filePath.rpartition(".")
    if a[1] == ""                     # no "." found, i. e. no extension
        fileInfo.basePath = filePath  # everything is path and base name
        fileInfo.extension = ""       # empty extension
    else
        fileInfo.basePath = a[0]
        fileInfo.extension = a[2].upcase
    end

    # separate basename and path
    pathSepPat = Regexp.new("[\\" + File::SEPARATOR + "\\" + File::ALT_SEPARATOR + "]")
    a = fileInfo.basePath.rpartition(pathSepPat)
    if a[1] == ""                     # no path separator found, i. e. no path
        fileInfo.pathName = ""        # empty path
        fileInfo.baseName = fileInfo.basePath
    else
        fileInfo.pathName = a[0] + a[1]
        fileInfo.baseName = a[2]
    end

    # determine default scale
    a = fileInfo.baseName.rindex(/[^0-9]/)+1
    l = fileInfo.baseName.length-1
    number = fileInfo.baseName[a..l].to_i
    if number >= 500 and number <= 10000000
        fileInfo.scale = number
    elsif number >= 6 and number <= 20
        fileInfo.scale = 500 * (2 ** (20 - number))
    end

    return fileInfo
end


##########################################################################
# Return true if the given file extension is supported, false otherwise
##########################################################################

def isSupportedFileExtension(fileExtension)
    case fileExtension.downcase
        when "bmp", "gif", "jpg", "jpeg",
             "pbm", "pgm", "png", "ppm",
             "tga", "tif", "tiff", "map"
            return true
        else
            return false
    end
end


##########################################################################
# Insert the given file into the given set of file infos, unless an
# entry for the same .map/imag file pair already exists
##########################################################################

def AddIfNoDupe(fileInfoSet, newFileInfo)
    # search through given set
    fileInfoSet.each { |fileInfo|
        if fileInfo.basePath == newFileInfo.basePath
            STDERR.print "  ERROR - #{newFileInfo.baseName}.#{newFileInfo.extension} is a dupe of\n"
            STDERR.print "          #{fileInfo.baseName}.#{fileInfo.extension}. Skipping!\n"
            return
        end
    }
    # not yet in given set, add
    fileInfoSet.push(newFileInfo)
end


##########################################################################
# Return valid (i.e. accessible) map file name, or nil if no map file
# found
##########################################################################

def ValidateMapFileName(fileNameBase)
    mapFileName = fileNameBase + ".MAP"
    if File.file? mapFileName
        return mapFileName
    end
    mapFileName = fileNameBase + ".map"
    if File.file? mapFileName
        return mapFileName
    end
    mapFileName = mapFileName.upcase
    if File.file? mapFileName
        return mapFileName
    end
    mapFileName = mapFileName.downcase
    if File.file? mapFileName
        return mapFileName
    end
    return nil
end


##########################################################################
# Return valid (i.e. accessible) picture file name, or nil if no picture
# file found
##########################################################################

def ValidatePicFileName(picFileNameMap, fileInfo)
    warn = false
    if fileInfo.extension != "MAP" and fileInfo.extension != ""
        # picture file name is given on command line
        picFileNameMapExt = GetFileInfo(picFileNameMap).extension
        if picFileNameMapExt != fileInfo.extension ||
           picFileNameMap.index(fileInfo.baseName) != 0
            # picture file name given on command line differs significantly
            # from map file contents
            STDERR.print "\n  WARNING - Picture file name given on command line differs\n"
            STDERR.print "            from the one contained in .map file.\n          "
            warn = true
        end
        # try file name from command line first
        fileName = fileInfo.basePath + "." + fileInfo.extension
        if File.file? fileName
            if warn
                STDERR.print "  Using picture file from command line.\n"
            end
            return fileName
        end
        fileName = fileInfo.basePath + "." + fileInfo.extension.downcase
        if File.file? fileName
            if warn
                STDERR.print "  Using picture file from command line.\n"
            end
            return fileName
        end
    end
    # no picture file given on command line, or picture file from command line
    # not found ==> try file name from map file, using path from command line
    filePath = fileInfo.pathName + picFileNameMap
    if File.file? filePath
        if warn
            STDERR.print "  Using picture file from map file.\n"
        end
        return filePath
    end
    filePath = fileInfo.pathName + picFileNameMap.upcase
    if File.file? filePath
        if warn
            STDERR.print "  Using picture file from map file.\n"
        end
        return filePath
    end
    filePath = fileInfo.pathName + picFileNameMap.downcase
    if File.file? filePath
        if warn
            STDERR.print "  Using picture file from map file.\n"
        end
        return filePath
    end
    return nil
end


##########################################################################
# Return true if given chart scale is valid. Issue error message and
# return false otherwise.
##########################################################################

def ChartScaleValid(scale)
    s = scale.to_i
    if scale != s.to_s
        STDERR.print "  ERROR - Given chart scale #{scale} is not a number.\n"
        return false
    elsif scale.to_i != 0 && (scale.to_i < 100 || scale.to_i > 10000000)
        STDERR.print "  ERROR - Given chart scale 1:#{scale} out of reasonable range.\n"
        return false
    end
    return true
end


##########################################################################
# Determine sign of latitude/longitude values based on typical suffix
# characters
##########################################################################

def LlSign(c)
   s = 0
   if c == "W" or c == "S"
       s = -1
   elsif c == "E" or c == "N"
       s = 1
   end
   return s
end


######################### Execution starts here ##########################


##########################################################################
# Initialize, get and check command line parameters
##########################################################################

puts "\nMap2Kap Version #{version}\n"
puts "Visit http://www.cruisersforum.com/forums/f134/ to get the\n"
puts "latest version, to report bugs, and to discuss enhancements.\n\n"

# print out usage info if no command line parameters given
unless ARGV[0]
    Usage()
    exit(false)
end

# get and process file names (command line parameters up to the first one
# that is purely numeric, which, if present, is assumed to be the scale)
STDERR.print "Collecting data...\n"
numInFilePairs = 0
fileInfo = []
while ARGV[0] && ARGV[0].to_i.to_s != ARGV[0]
    argFileName = ARGV[0]
    ARGV.shift
    numInFilePairs += 1
    curFileInfo = GetFileInfo(argFileName)

    # pre-check file extension
    errName = curFileInfo.baseName + "." + curFileInfo.extension
    unless isSupportedFileExtension(curFileInfo.extension)
        STDERR.print "  ERROR - File type extension of #{errName}\n"
        STDERR.print "          not supported. Skipping!\n"
        next
    end

    # pre-check map file
    mapFileName = ValidateMapFileName(curFileInfo.basePath)
    unless mapFileName
        STDERR.print "  ERROR - Can't find map file for #{errName}.\n"
        STDERR.print "          Skipping!\n"
        next
    end

    # survived all checks, add to list for processing
    AddIfNoDupe(fileInfo, curFileInfo)
end

# get chart scale from command line (if given) or prompt user
if ARGV[0]
    chartScaleParam = ARGV[0]
    unless ChartScaleValid(chartScaleParam)
        STDERR.print "        Aborting!\n"
        exit(false)
    end
else
    chartScaleParam = "0"
    fileInfo.each { |curFileInfo|
        unless curFileInfo.scale
            begin
                print "  Enter scale (or 0 to skip) for \"#{curFileInfo.baseName}\" 1:"
                scale = gets.strip
            end until ChartScaleValid(scale)
            curFileInfo.scale = scale.to_i
        end
    }
end

# get and check optional soundings parameters
if ARGV[1]
    soundingUnit = ARGV[1]
else
    soundingUnit = "Meters" 
end    
if ARGV[2]
    soundingDatum = ARGV[2]
else
    soundingDatum = "UNKNOWN"
end

# get and check optional coordinate adjustment values (5th and 6th on command line)
if ARGV[3] and ARGV[4]
    latitudeAdjust  = ARGV[3]     # latitude adjustment to wgs84
    longitudeAdjust = ARGV[4]     # longitude adjustment to wgs 84
elsif ARGV[3] == nil and ARGV[4] == nil
    latitudeAdjust  = ""
    longitudeAdjust = ""
else
    STDERR.print "ERROR - Either both longitude and latitude adjustments must be\n"
    STDERR.print "        given on command line, or none of them. Aborting!\n"
    exit(false)
end


##########################################################################
# process all given files
##########################################################################

unless fileInfo.size > 0
    STDERR.print "No files to process!\n"
    exit(false)
end

case numInFilePairs
    when 1
        STDERR.print "Processing file...\n"
    when fileInfo.size
        STDERR.print "Processing #{fileInfo.size} files...\n"
    else
        STDERR.print "Processing #{fileInfo.size} out of #{numInFilePairs} given files...\n"
end

numOutFiles = 0

fileInfo.each { |curFileInfo|

    STDERR.print "  \"#{curFileInfo.baseName}\""


    # get access to current map file
    ######################################################################

    mapFileName = ValidateMapFileName(curFileInfo.basePath)
    mapBaseName = GetFileInfo(mapFileName).baseName


    # get chart scale for current file
    ######################################################################

    if chartScaleParam.to_i != 0
        chartScale = chartScaleParam.to_i
    else
        chartScale = curFileInfo.scale
        unless chartScale      # with the new interactive entry, this should never happen
            STDERR.print "\n  ERROR - Can't determine chart scale (not given on command line\n"
            STDERR.print "          and no recognizable zoom level in file name). Skipping!\n"
            next
        end
        unless chartScale > 0  # user entered scale = 0 to skip
            STDERR.print " -> Skipping upon user request (scale = 0).\n"
            next
        end
    end
    STDERR.print " @ 1:#{chartScale}"


    # read & process map file
    ######################################################################

    # read map file into array of lines
    mapFileLines = File.readlines(mapFileName)
    lineNumber   = 0

    # 1st line must be V2 Ozi file header
    unless mapFileLines[0] =~ /OziExplorer Map Data File Version 2\./
        STDERR.print "\n  ERROR - \"#{mapBaseName}\" is not a valid\n"
        STDERR.print "          Version 2 Ozi map file. Skipping!\n"
        next
    end

    # 2nd line is chart title
    chartTitle = mapFileLines[1].strip

    # 3rd line is picture file name
    picFileName = ValidatePicFileName(mapFileLines[2].strip, curFileInfo)
    unless picFileName
        STDERR.print "\n  ERROR - Can't find picture file for \"#{mapBaseName}\".\n"
        STDERR.print "          Skipping!\n"
        next
    end

    # skip line 4 (Map Code entry)
    lineNumber = 4

    # determine chart datum and adjustment
    datumAdjustItems = mapFileLines[lineNumber].split(",")
    lineNumber += 1
    # remove all blanks from chart datum, also those in the middle
    chartDatum         = datumAdjustItems[0].delete(' ')
    tmpLatitudeAdjust  = datumAdjustItems[2].strip.to_f
    tmpLongitudeAdjust = datumAdjustItems[3].strip.to_f
    if latitudeAdjust != "" and longitudeAdjust != ""
        # prefer adjustment values given on command line
        latitudeAdjust  =  latitudeAdjust.to_f
        longitudeAdjust = longitudeAdjust.to_f
        if (tmpLatitudeAdjust != 0.0 and tmpLatitudeAdjust != latitudeAdjust) or
           (tmpLongitudeAdjust != 0.0 and tmpLongitudeAdjust != longitudeAdjust)
            STDERR.print "\n  WARNING - Latitude/longitude adjustments given on command\n"
            STDERR.print "            line override non-zero adjustments given in\n"
            STDERR.print "            \"#{mapBaseName}\".\n"
        end
    else
        # use adjustments from 5th line of map file only if not given on command line
        latitudeAdjust  = tmpLatitudeAdjust
        longitudeAdjust = tmpLongitudeAdjust
    end
    if (latitudeAdjust != 0.0 or longitudeAdjust != 0.0) and (chartDatum != "WGS84")
        STDERR.print "\n  WARNING - Unsupported combination of latitude/longitude adjust-\n"
        STDERR.print "            ments and chart datum. Assuming WGS84 chart datum\n"
        STDERR.print "            instead of #{chartDatum}.\n"
        chartDatum = "WGS84"
    end

    # skip unneccessary lines
    # (typically containing "Reserved" and "Magnetic Variation" entries)
    while mapFileLines[lineNumber] !~/Projection/
        lineNumber += 1
    end

    # read and process "Map Projection" entry
    projection = mapFileLines[lineNumber].split(",")[1].upcase 
    lineNumber += 1
    unless projection =~ /TRANSVERSE|POLYCONIC|UTM/
        projection = "MERCATOR"
    end
    if projection =~ /TRANSVERSE/
        projection = "TRANSVERSE MERCATOR"
    end
    if projection =~ /UNIVERSAL|UTM/
        projection = "UTM"
    end

    # skip unneccessary lines
    # (typically there aren't any, but who knows...)
    while mapFileLines[lineNumber] !~/Point/
        lineNumber += 1
    end

    # read calibration points
    # (there could be as few as four or as many as 30 of them)
    ref   = []
    start = lineNumber
    while mapFileLines[lineNumber] =~ /Point/
        ref[lineNumber-start] = mapFileLines[lineNumber].split(",")
        lineNumber += 1
    end
    numRef = lineNumber - start

    # skip unneccessary lines
    # (typically containing "Projection Setup" up to "MMPNUM" entries,
    # and some abbreviation definitions in between these two)
    while mapFileLines[lineNumber] !~ /MMPNUM/
        lineNumber += 1
    end

    # read map boundary polygon/rectangle (PLYs) from MMPNUM, MMPXY, and MMPLL entries
    numPly = mapFileLines[lineNumber].split(",")[1].to_i
    lineNumber += 1
    if numPly < 4
        STDERR.print "\n  ERROR - Not enough MMP entries in \"#{mapBaseName}\".\n"
        STDERR.print "          Skipping!\n"
        next
    end
    if numPly > 4
        STDERR.print "\n  WARNING - Non-quadrangular map boundary (more than 4 MMP entries)\n"
        STDERR.print "            found in \"#{mapBaseName}\".\n"
    end
    plyxy = []
    start = lineNumber
    while mapFileLines[lineNumber] =~/MMPXY/
        plyxy[lineNumber-start]= mapFileLines[lineNumber].split(",")
        lineNumber += 1
    end
    if lineNumber - start != numPly
        STDERR.print "\n  ERROR - Wrong number of MMPXY entries in \"#{mapBaseName}\".\n"
        STDERR.print "          Skipping!\n"
        next
    end
    plyll = []
    start = lineNumber
    while mapFileLines[lineNumber] =~/MMPLL/
        plyll[lineNumber-start]= mapFileLines[lineNumber].split(",")
        lineNumber += 1
    end
    if lineNumber - start != numPly
        STDERR.print "\n  ERROR - Wrong number of MMPLL entries in \"#{mapBaseName}\".\n"
        STDERR.print "          Skipping!\n"
        next
    end

    # skip unneccessary lines
    # (typically a single MOP entry)
    while mapFileLines[lineNumber] !~/IWH/
        lineNumber += 1
    end

    # read picture size in pixels from IWH entry
    iwh = mapFileLines[lineNumber].split(",")
    lineNumber += 1
    picPixelWidth  = iwh[2].to_i
    picPixelHeight = iwh[3].to_i
    if picPixelWidth < 1 or picPixelHeight < 1
        STDERR.print "\n  ERROR - No picture size (IWH entry) in \"#{mapBaseName}\".\n"
        STDERR.print "          Skipping!\n"
        next
    end


    # Calculate Projection Parameter
    # (This may not work correctly for Transverse Mercator and Polyconic
    # projection, or in cases where we have more than 4 PLYs)
    ######################################################################

    if projection == "MERCATOR"
        projectionParam = (plyll[0][3].to_f + plyll[1][3].to_f +
                           plyll[2][3].to_f + plyll[3][3].to_f )/4
    elsif projection == "TRANSVERSE MERCATOR" || projection == "POLYCONIC"
        projectionParam = (plyll[0][2].to_f + plyll[1][2].to_f +
                           plyll[2][2].to_f + plyll[3][2].to_f )/4
        STDERR.print "  WARNING - Transverse Mercator or Polyconic projection found\n"
        STDERR.print "            in \"#{mapBaseName}\".\n"
    elsif projection == "UTM"
        projectionParam  = (plyll[0][2].to_f + plyll[1][2].to_f +
                            plyll[2][2].to_f + plyll[3][2].to_f )/4
        # try to use the central meridian in each UTM zone
        ppSign = 1
        if projectionParam < 0
            ppSign = -1
        end
        projectionParam = (projectionParam/6).to_i*6 + ppSign*3       
    else
        STDERR.print "\n  ERROR - Unsupported map projection in \"#{mapBaseName}\".\n"
        STDERR.print "          Cannot determine projection parameters. Skipping!\n"
        next
    end


    # Write BSB/KAP header file
    #   See http://libbsb.sourceforge.net/bsb_file_format.html
    #   for a description of the file format
    ######################################################################

    hdrFileName = curFileInfo.basePath + ".txt"

    open(hdrFileName,"w") do |h|

        h.puts "! Converted Ozi Explorer .map file"
        h.puts "! Converted with map2kap Version #{version}"
        h.puts "VER/2.0"
        h.puts "BSB/NA=#{chartTitle}"
        h.puts "    NU=1"
        h.puts "    RA=#{picPixelWidth},#{picPixelHeight},DU="
        h.puts "KNP/SC=#{chartScale},GD=#{chartDatum.upcase},PR=#{projection}"
        h.puts "    PP=#{projectionParam},PI=UNKNOWN,SP=UNKNOWN,SK=0.0"
        h.puts "    UN=#{soundingUnit.upcase},SD=#{soundingDatum},DX=000,DY=000"
        t = Time.now
        h.puts "CED/SE=,RE=,ED=#{t.strftime("%m/%d/%Y")}"

        # create REF entries from PLYs
        ofs = 1
        for i in 0 .. (numPly - 1)
            refX   = plyxy[i][2].strip
            refY   = plyxy[i][3].strip
            refLon = plyll[i][3].strip
            refLat = plyll[i][2].strip
            h.puts "REF/#{i+ofs},#{refX},#{refY},#{refLon},#{refLat}"
        end

        # create further REF entries from Calibration Points
        ofs += numPly
        for i in 0 .. (numRef - 1)
            refX   = ref[i][2].strip
            refY   = ref[i][3].strip
            # skip empty calibration points
            if refX != "" and refY != ""
                refLon = (ref[i][6].to_i + ref[i][7].to_f/60) *
                         LlSign( ref[i][8].strip)
		    refLat = (ref[i][9].to_i + ref[i][10].to_f/60) *
                         LlSign(ref[i][11].strip)
                h.puts "REF/#{i+ofs},#{refX},#{refY},#{refLon},#{refLat}"
            else
                # make sure REFs are numbered without gaps even if
                # empty calibration points are found in the middle
                ofs -= 1
            end
        end

        # create PLY entries (not sure whether this is correct for more than 4 PLYs)
        ofs = 1
        for i in 0 .. (numPly - 1)
            h.puts "PLY/#{i+ofs},#{plyll[i][3].strip},#{plyll[i][2].strip}"
        end

        # create DTM entry from latitude/longitude adjustments
        h.puts "DTM/#{latitudeAdjust},#{longitudeAdjust}"
        # no IFM entry needed (imgkap will add it)
    end


    # Merge header and picture files to BSB/KAP file
    ######################################################################

    # picture file name has already been checked

    # determine imgkap options for day/night color palette based on picture file type
    case picFileName
        when /.*[jJ][pP][eE]?[gG]/    # assume JPEG files are aerial/satellite photos
            opts = "-p IMG"
        else                          # assume all other file types are map scans
            opts = "-p MAP"
    end

    # pass header and picture files to imgkap for further processing
    kapFileName = curFileInfo.basePath + ".kap"
    if system("#{imgkap} #{opts} \"#{picFileName}\" \"#{hdrFileName}\" \"#{kapFileName}\"")
        STDERR.print "  -> \"#{curFileInfo.baseName}.kap\"\n"
        numOutFiles += 1
    else
        STDERR.print "\n  ERROR - System call to imgkap.exe failed. Skipping!\n"
    end


    # Clean up (OK to leave temp files around in error case, might be
    # helpful for debugging)
    ######################################################################

    File.unlink hdrFileName  if File.file? hdrFileName

} # end fileInfo.each


# issue statistics and caution message according to number of
# created KAP files
##########################################################################

case numOutFiles
    when 0
        puts "No files converted."
    when numInFilePairs
        case numInFilePairs
            when 1
                puts "Given file successfully converted."
            when 2
                puts "Both given files successfully converted."
            else
                puts "All #{numOutFiles} given files successfully converted."
        end
    else # less than numInFilePairs processed
        puts "#{numOutFiles} out of #{numInFilePairs} given files successfully converted."
end

case numOutFiles
    when 0
        # no further output
    when 1
        puts "Check your output file carefully before use!"
    else
        puts "Check your output files carefully before use!"
end

# EOF