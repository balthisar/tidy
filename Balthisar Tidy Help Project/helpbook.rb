################################################################################
#  helpbook.rb
#    Consists of the Helpbook class which performs additional functions for
#    generating Apple Helpbooks with Middleman.
#
#    - Build automatic CSS max-width for all images.
#    - Build a partial containing markdown links to all html file.
#    - Build a partial containing markdown links to all images.
#    - Process *.plist files with data for building a helpbook.
#    - Provides helpers for determining build targets.
#    - Provides functions for simplifying dealing with the sitemap.
################################################################################

require 'fastimage'
require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'yaml'


class Helpbook < Middleman::Extension


#===============================================================
#  Configuration options
#===============================================================

option :target, 'default', 'The default target to process if not specified.'
option :CFBundleName, nil, 'The CFBundleName key; will be used in a lot of places.'
option :HelpOutputLocation, nil, 'Directory to place the built helpbook.'
option :Targets, nil, 'A data structure that defines many characteristics of the target.'
option :build_markdown_links, true, 'Whether or not to generate `_markdown-links.erb`'
option :build_markdown_images, true, 'Whether or not to generate `_markdown-images.erb`'
option :build_image_width_css, true, 'Whether or not to generate `_image_widths.scss`'

option :file_mdimages, '_markdown-images.erb', 'Filename for the generated images markdown file.'
option :file_mdlinks,  '_markdown-links.erb',  'Filename for the generated links markdown file.'
option :file_imagecss, '_image_widths.scss', 'Filename for the generated image width css file.'
option :file_titlepage_template, '_title_page.html.md.erb', 'Filename of the template for the title page.'


#===============================================================
#  initializer
#===============================================================
def initialize(app, options_hash={}, &block)
  super
  app.extend ClassMethods

  # ensure target exists
  unless options.Targets.key?(options.target)
    STDOUT.puts "`#{options.target}` is not a valid target. Choose from one of:"
    options.Targets.each do |k,v|
      STDOUT.puts "  #{k}"
    end
    STDOUT.puts "Or use nothing for the default target."
    exit 1
  else
    STDOUT.puts "Using target `#{options.target}`"
  end

  @path_content = nil; # string will be initialized in after_configuration.

end #initialize


#===============================================================
#  after_configuration
#    Callback occurs before before_build.
#    Here we will adapt the middleman config.rb settings to the
#    current target settings. This is also our only chance to
#    create files that will be processed (by time we get to
#    before_build, middleman already has its manifest).
#===============================================================
def after_configuration

  # Setup some instance variables
  @path_content = File.join( app.source, "Resources/", "Base.lproj/" )


  # Set the correct :build_dir based on the options.
  app.set :build_dir, File.join(options.HelpOutputLocation, "#{options.CFBundleName} (#{options.target}).help", "Contents")


  # Set the destinations for generated markdown partials and css.
  options.file_mdimages = File.join(app.source, app.partials_dir, options.file_mdimages)
  options.file_mdlinks  = File.join(app.source, app.partials_dir, options.file_mdlinks)
  options.file_imagecss = File.join(app.source, app.css_dir, options.file_imagecss)


  # make the title page
  srcFile = File.join(@path_content, options.file_titlepage_template)
  dstFile = File.join(@path_content, "#{options.CFBundleName}.html.md.erb")
  FileUtils.cp(srcFile, dstFile)


  # create all other necessary files
  process_plists
  build_mdimages
  build_mdlinks
  build_imagecss

end #def


#===============================================================
#  before_build
#    Callback occurs one time before the build starts.
#    We will peform all of the required pre-work.
#===============================================================
def before_build

end

#===============================================================
#  after_build
#    Callback occurs one time after the build.
#    We will peform all of the finishing touches.
#===============================================================
def after_build
    run_help_indexer
end


#===============================================================
#  Helpers
#    Methods defined in this helpers block are available in
#    templates.
#===============================================================

helpers do

  #--------------------------------------------------------
  # target_name
  #   Return the current build target.
  #--------------------------------------------------------
  def target_name
    extensions[:Helpbook].options.target
  end


  #--------------------------------------------------------
  # target_name?
  #   Return the current build target.
  #--------------------------------------------------------
  def target_name?(proposal)
    options = extensions[:Helpbook].options.target == proposal
  end


  #--------------------------------------------------------
  # target_feature?
  #   Does the target have the feature `feature`?
  #--------------------------------------------------------
  def target_feature?(feature)
    options = extensions[:Helpbook].options
    features = options.Targets[options.target][:Features]
    result = features.key?(feature) && features[feature]
  end


  #--------------------------------------------------------
  # product_name
  #   Returns the product name for the current target
  #--------------------------------------------------------
  def product_name
    options = extensions[:Helpbook].options
    options.Targets[options.target][:ProductName]
  end


  #--------------------------------------------------------
  # cfBundleName
  #   Returns the product CFBundleName for the current
  #   target
  #--------------------------------------------------------
  def cfBundleName
    extensions[:Helpbook].options.CFBundleName
  end


  #--------------------------------------------------------
  # cfBundleIdentifier
  #   Returns the product CFBundleIdentifier for the
  #   current target
  #--------------------------------------------------------
  def cfBundleIdentifier
    options = extensions[:Helpbook].options
    options.Targets[options.target][:CFBundleID]
  end


  #--------------------------------------------------------
  # boolENV
  #   Treat an environment variable with the value 'yes' or
  #   'no' as a bool. Undefined ENV are no, and anything
  #   that's not 'yes' is no.
  #--------------------------------------------------------
  def boolENV(envVar)
     (ENV.key?(envVar)) && !((ENV[envVar].downcase == 'no') || (ENV[envVar].downcase == 'false'))
  end


  #--------------------------------------------------------
  #  page_name
  #    Make page_name available for each page. This is the
  #    file base name. Useful for assigning classes, etc.
  #--------------------------------------------------------
  def page_name
    File.basename( current_page.url, ".*" )
  end


  #--------------------------------------------------------
  #  page_group
  #    Make page_group available for each page. This is the
  #    source parent directory (not the request path).
  #    Useful for for assigning classes, and/or group
  #    conditionals.
  #--------------------------------------------------------
  def page_group
    File.basename(File.split(current_page.source_file)[0])
  end


  #--------------------------------------------------------
  #  current_group_pages
  #    Returns an array of all of the pages in the current
  #    group, i.e., pages in the same source subdirectory
  #    that are HTML files.
  #--------------------------------------------------------
  def current_group_pages
    sitemap.resources.find_all do |p|
      p.path.match(/\.html/) &&
      File.basename(File.split(p.source_file)[0]) == page_group
    end
  end


  #--------------------------------------------------------
  #  related_pages
  #    Returns an array of all of the pages related to the
  #    current page's group. See pages_related_to.
  #--------------------------------------------------------
   def related_pages
       pages_related_to( page_group )
   end


  #--------------------------------------------------------
  #  pages_related_to(group)
  #    Returns an array of all of the pages in the
  #    specified group, defined as:
  #      - that are HTML files
  #      - that are in the same group
  #      - are NOT the current page
  #      - is not the index page beginning with 00
  #      - do have an "order" key in the frontmatter
  #      - if frontmatter:target is used, the target or
  #        feature appears in the frontmatter
  #      - if frontmatter:exclude is used, that target or
  #        enabled feature does NOT appear in the
  #        frontmatter.
  #    Returned array will be:
  #      - sorted by the "order" key.
  #
  # Also adds a .metadata[:link] to the structure with a
  # relative path to groups that are not the current group.
  #--------------------------------------------------------
  def pages_related_to( group )
     pages = sitemap.resources.find_all do |p|
      p.path.match(/\.html/) &&
      File.basename(File.split(p.source_file)[0]) == group &&
      File.basename( p.url, ".*" ) != page_name &&
      !File.basename( p.url ).start_with?("00") &&
      p.data.key?("order") &&
      ( !p.data.key?("target") || (p.data["target"].include?(target_name) || p.data["target"].count{ |t| target_feature?(t) } > 0) ) &&
      ( !p.data.key?("exclude") || !(p.data["exclude"].include?(target_name) || p.data["exclude"].count{ |t| target_feature(t) } > 0) )
    end
    pages.each { |p| p.add_metadata(:link =>(group == page_group) ? File.basename(p.url) : File.join(group, File.basename(p.url) ) )}
    pages.sort_by { |p| p.data["order"].to_i }
  end

end #helpers


#===============================================================
#  Instance Methods
#===============================================================


  #--------------------------------------------------------
  #  build_mdimages
  #    Will build a markdown file with shortcuts to links
  #    for every image found in the project.
  #--------------------------------------------------------
  def build_mdimages

    return unless options.build_markdown_images

    STDOUT.puts "Helpbook is creating `#{options.file_mdimages}`."

    files_array = []
    out_array = []
    longest_shortcut = 0
    longest_path = 0

    Dir.glob("#{app.source}/Resources/**/*.{jpg,png,gif}").each do |fileName|

        # Remove all file extensions and make a shortcut
        base_name = fileName
        while File.extname(base_name) != "" do
            base_name = File.basename( base_name, ".*" )
        end
        next if base_name.start_with?('_')
        shortcut = "[#{base_name}]:"

        # Make a fake absolute path
        path = File::SEPARATOR + Pathname.new(fileName).relative_path_from(Pathname.new(app.source)).to_s

        files_array << { :shortcut => shortcut, :path => path }

        longest_shortcut = shortcut.length if shortcut.length > longest_shortcut
        longest_path = path.length if path.length > longest_path

    end

    files_array = files_array.sort_by { |key| [File.split(key[:path])[0], key[:path]] }
    files_array.uniq.each do |item|
        item[:shortcut] = "%-#{longest_shortcut}.#{longest_shortcut}s" % item[:shortcut]
        item[:path] = "%-#{longest_path}.#{longest_path}s" % item[:path]
        out_array << "#{item[:shortcut]}  #{item[:path]}   "
    end

    File.open(options.file_mdimages, 'w') { |f| out_array.each { |line| f.puts(line) } }

  end #def


  #--------------------------------------------------------
  #  build_mdlinks
  #    Will build a markdown file with shortcuts to links
  #    for every HTML file found in the project.
  #--------------------------------------------------------
  def build_mdlinks
    return unless options.build_markdown_links

    STDOUT.puts "Helpbook is creating `#{options.file_mdlinks}`."

    files_array = []
    out_array = []
    longest_shortcut = 0
    longest_path = 0

    Dir.glob("#{app.source}/Resources/**/*.erb").each do |fileName|

        # Remove all file extensions and make a shortcut
        base_name = fileName
        while File.extname(base_name) != "" do
            base_name = File.basename( base_name, ".*" )
        end
        next if base_name.start_with?('_')

        shortcut = "[#{base_name}]:"

        # Make a fake absolute path
        path = Pathname.new(fileName).relative_path_from(Pathname.new(app.source))
        path = File::SEPARATOR + File.join(File.dirname(path), base_name) + ".html"

        # Get the title, if any
        metadata = YAML.load_file(fileName)
        title = (metadata.is_a?(Hash) && metadata.key?("title")) ? metadata["title"] : ""

        files_array << { :shortcut => shortcut, :path => path, :title => title }

        longest_shortcut = shortcut.length if shortcut.length > longest_shortcut
        longest_path = path.length if path.length > longest_path

    end

    files_array = files_array.sort_by { |key| [File.split(key[:path])[0], key[:path]] }
    files_array.uniq.each do |item|
        item[:shortcut] = "%-#{longest_shortcut}.#{longest_shortcut}s" % item[:shortcut]

        if item[:title].length == 0
            out_array << "#{item[:shortcut]}  #{item[:path]}"
        else
            item[:path] = "%-#{longest_path}.#{longest_path}s" % item[:path]
            out_array << "#{item[:shortcut]}  #{item[:path]}  \"#{item[:title]}\""
        end
    end

    File.open(options.file_mdlinks, 'w') { |f| out_array.each { |line| f.puts(line) } }

  end #def


  #--------------------------------------------------------
  #  build_imagecss
  #    Builds a css file containing an max-width for every
  #    image in the project.
  #--------------------------------------------------------
  def build_imagecss
    return unless options.build_image_width_css

    STDOUT.puts "Helpbook is creating `#{options.file_imagecss}`."

    out_array = []

    Dir.glob("#{app.source}/Resources/**/*.{jpg,png,gif}").each do |fileName|
        # fileName contains complete path relative to this script.
        # Get just the name and extension.
        base_name = File.basename(fileName)

        # width
        if File.basename(base_name, '.*').end_with?("@2x")
          width = (FastImage.size(fileName)[0] / 2).to_i.to_s
        else
          width = FastImage.size(fileName)[0].to_s;
        end

        # proposed css
        out_array << "img[src$='#{base_name}'] { max-width: #{width}px; }"
    end

    File.open(options.file_imagecss, 'w') { |f| out_array.each { |line| f.puts(line) } }

  end #def


  #--------------------------------------------------------
  #  process_plists
  #    Performs substitutions in all _*.plist and
  #    _*.strings files in the project.
  #--------------------------------------------------------
  def process_plists

    Dir.glob("#{app.source}/**/_*.{plist,strings}").each do |fileName|

      STDOUT.puts "Helpbook is processing plist file #{fileName}."

        file = File.open(fileName)
        doc = Nokogiri.XML(file)
        file.close

        doc.traverse do |node|
          if node.text?
            node.content = node.content.gsub('{$CFBundleIdentifier}', options.Targets[options.target][:CFBundleID])
            node.content = node.content.gsub('{$CFBundleName}', options.CFBundleName)
          end
        end

        dst_path = File.dirname(fileName)
        dst_file = File.basename(fileName)[1..-1]

        File.open(File.join(dst_path, dst_file),'w') {|f| doc.write_xml_to f}

    end
  end #def


  #--------------------------------------------------------
  #  run_help_indexer
  #--------------------------------------------------------
  def run_help_indexer

    # see whether a help indexer is available.
    `command -v hiutil > /dev/null`
    if $?.success?

      indexDir = File.expand_path(File.join(app.build_dir, "Resources/", "Base.lproj/" ))
      indexDst = File.expand_path(File.join(indexDir, "#{options.CFBundleName}.helpindex"))

      STDOUT.puts "'#{indexDir}' (indexing)"
      STDOUT.puts "'#{indexDst}' (final file)"

      `hiutil -Cf "#{indexDst}" "#{indexDir}"`
    else
      STDOUT.puts "NOTE: `hituil` is not on path or not installed. No index will exist for target '#{options.target}'."
    end
  end #def


#===============================================================
#  ClassMethods
#===============================================================

module ClassMethods

end #module


end #class


::Middleman::Extensions.register(:Helpbook, Helpbook)
