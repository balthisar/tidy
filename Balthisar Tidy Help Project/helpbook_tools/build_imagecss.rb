#!/usr/bin/env ruby

###############################################################################
# build_imagecss.rb
#   We will seek every image in Contents (source)/Resources and build CSS that
#   represents an image-width constraint in the manner:
#      img[src$="filename.png"] { max-width: 000px; }
#   Dumps to stdout.
###############################################################################

require 'fileutils'
require 'pathname'
require 'fastimage'  # gem install fastimage

filesArray = []
outArrayFiles = []

Dir.glob("Contents (source)/Resources/**/*.{jpg,png,gif}").each do |fileName|

    # fileName contains complete path relative to this script.
    # Get just the name and extension.
    base_name = File.basename(fileName)

    # width
    width = FastImage.size(fileName)[0].to_s;

    # proposed css
    rule = "img[src$='#{base_name}'] { max-width: #{width}px; }"

    puts rule
end

exit 0
