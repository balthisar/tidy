#!/usr/bin/env ruby

###############################################################################
# build_links.rb
#   This will look for .erb files in the Contents (source)/Resources
#   directory and dump it to standard out.
###############################################################################

require 'fileutils'
require 'pathname'
require 'yaml'

filesArray = []
longestShortcut = 0
longestPath = 0

outArrayFiles = []

Dir.glob("Contents (source)/Resources/**/*.erb").each do |fileName|

    # Remove all file extensions and make a shortcut
    base_name = fileName
    while File.extname(base_name) != "" do
        base_name = File.basename( base_name, ".*" )
    end
    shortcut = "[#{base_name}]:" #.gsub("-", "_")

    # Make a fake absolute path
    path = Pathname.new(fileName).relative_path_from(Pathname.new("Contents (source)"))
    path = File::SEPARATOR + File.join(File.dirname(path), base_name) + ".html"

    # Get the title, if any
    metadata = YAML.load_file(fileName)
    title = (metadata.is_a?(Hash) && metadata.key?("title")) ? metadata["title"] : ""

    filesArray << { :shortcut => shortcut, :path => path, :title => title }

    longestShortcut = shortcut.length if shortcut.length > longestShortcut
    longestPath = path.length if path.length > longestPath

end

#filesArray = filesArray.sort_by { |key| [key[:path].count('/'), key[:path]] }
filesArray = filesArray.sort_by { |key| [File.split(key[:path])[0], key[:path]] }
filesArray.uniq.each do |item|

    item[:shortcut] = "%-#{longestShortcut}.#{longestShortcut}s" % item[:shortcut]

    if item[:title].length == 0
        outArrayFiles << "#{item[:shortcut]}  #{item[:path]}"
    else
        item[:path] = "%-#{longestPath}.#{longestPath}s" % item[:path]
        outArrayFiles << "#{item[:shortcut]}  #{item[:path]}  \"#{item[:title]}\""
    end
end


filesArray = []
longestShortcut = 0
longestPath = 0

outArrayLinks = []


Dir.glob("Contents (source)/Resources/**/*.{jpg,png,gif}").each do |fileName|

    # Remove all file extensions and make a shortcut
    base_name = fileName
    while File.extname(base_name) != "" do
        base_name = File.basename( base_name, ".*" )
    end
    shortcut = "[#{base_name}]:" # .gsub("-", "_")

    # Make a fake absolute path
    path = File::SEPARATOR + Pathname.new(fileName).relative_path_from(Pathname.new("Contents (source)")).to_s

    filesArray << { :shortcut => shortcut, :path => path }

    longestShortcut = shortcut.length if shortcut.length > longestShortcut
    longestPath = path.length if path.length > longestPath

end

#filesArray = filesArray.sort_by { |key| [key[:path].count('/'), key[:path]] }
filesArray = filesArray.sort_by { |key| [File.split(key[:path])[0], key[:path]] }
filesArray.uniq.each do |item|
    item[:shortcut] = "%-#{longestShortcut}.#{longestShortcut}s" % item[:shortcut]
    item[:path] = "%-#{longestPath}.#{longestPath}s" % item[:path]
    outArrayLinks << "#{item[:shortcut]}  #{item[:path]}   "
end

puts outArrayFiles
puts "\n====================================================\n"
puts outArrayLinks
puts "\n"


