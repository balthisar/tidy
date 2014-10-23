#!/usr/bin/env ruby
###############################################################################
#  middlemac.rb - v1.0RC1
#
#    Consists of both:
#    - the `middlemac` command-line tool for invoking Middleman with multiple
#      targets, as well as some basic utilities, and
#
#    - the `Middlemac` class that Middleman requires to perform additional
#      functions related to generating Apple Helpbooks.
#
#    Together, they will:
#    - Build automatic CSS max-width for all images.
#    - Build a partial containing markdown links to all html file.
#    - Build a partial containing markdown links to all images.
#    - Process *.plist files with data for building a helpbook.
#    - Provide helpers for determining build targets.
#    - Provide functions for simplifying dealing with the sitemap.
#
#    Building:
#    - ./middlemac.rb target-1 target-2 target-n || all
#    - HBTARGET=target middleman build
#    - HBTARGET=target bundle exec middleman build
#
#    Note:
#     In a better world this file would be split up, of course. For end-user
#     convenience and ease of distribution, this single file script is used.
###############################################################################

require 'fastimage'
require 'fileutils'
require 'nokogiri'
require 'pathname'
require 'yaml'


#---------------------------------------------------------------
# ANSI terminal codes for use in documentation strings.
#---------------------------------------------------------------
A_BLUE      = "\033[34m"
A_CYAN      = "\033[36m"
A_GREEN     = "\033[32m"
A_RED       = "\033[31m"
A_RESET     = "\033[0m"
A_UNDERLINE = "\033[4m"


#---------------------------------------------------------------
# Output in color and abstract standard out.
#---------------------------------------------------------------
def puts_blue(string)
  puts "\033[34m" + string + "\033[0m"
end
def puts_cyan(string)
  puts "\033[36m" + string + "\033[0m"
end
def puts_green(string)
  puts "\033[32m" + string + "\033[0m"
end
def puts_red(string)
  puts "\033[31m" + string + "\033[0m"
end
def puts_yellow(string)
  puts "\033[33m" + string + "\033[0m" # really ANSI brown
end


#---------------------------------------------------------------
# Command-Line documentation.
#---------------------------------------------------------------
def documentation(targets_array)
<<-HEREDOC
#{A_CYAN}This tool generates a complete Apple Help Book using Middleman as
a static generator, and supports multiple build targets. It is
necessary to specify one or more build targets.

  #{A_UNDERLINE}Use:#{A_RESET}#{A_CYAN}
#{targets_array.sort.collect { |item| "    middlemac #{item}"}.join("\n")}
    middlemac all

Also, any combination of #{targets_array.join(', ')} or all can be used to build
multiple targets at the same time.

  #{A_UNDERLINE}Switches:#{A_RESET}#{A_CYAN}
    -v, --verbose    Executes Middleman in verbose mode for each build target.
    -q, --quiet      Silences Middleman output, even if --verbose is specified.
    -s, --server     Runs Middleman in server mode. Server target is undefined if more than one or all is specified!
    -h, --help       Displays this help and doesn’t process files or run server.#{A_RESET}

HEREDOC
end



##########################################################################
#  Command-Line Script
#    Slow to use for a single target, because we run Middleman once in
#    order to get a list of the valid targets. However it's useful for
#    building multiple targets, if desired.
##########################################################################
if __FILE__ == $0

  # Lower-case everything and eliminate duplicate arguments.
  targets = ARGV.map(&:downcase).uniq

  # Find out if there are any switches.
  # can be -q, --quiet, -v, --verbose
  BE_QUIET = targets.include?('-q') || targets.include?('--quiet')
  BE_VERBOSE = targets.include?('-v') || targets.include?('--verbose')
  BE_SERVER = targets.include?('-s') || targets.include?('--server')
  BE_HELPFUL = targets.include?('-h') || targets.include?('--help')

  # Remove switches.
  targets.delete_if {|item| %w(-q --quiet -v --verbose -s --server -h --help).include?(item)}

  # Build an array of valid targets. This detection
  # mechanism is a bit slow, in that it invokes Middleman.
  puts_blue 'Determining valid targets…'
  valid_targets = `HBTARGET=improbable_value bundle exec middleman build`.split("\n")

  # Show help and exit without error.
  if BE_HELPFUL || targets.count == 0
    puts documentation(valid_targets)
    exit 0
  end

  # Ensure each argument is valid, and exit with error if not.
  # If there's only a single 'all' target then we're okay. This
  # prevents action if the user specifies an invalid target but
  # also uses 'all'.
  if (targets & valid_targets).count < 1 && !(targets.count == 1 && targets.include?('all'))
    puts documentation(valid_targets)
    exit 1
  end

  if BE_SERVER

    # Select a target in case user specified more than one.
    target = targets.first == 'all' ? valid_targets.first : targets.first
    puts_blue "Starting server for target '#{target}'"
    puts_blue 'Use Ctrl-C to stop the server.'
    system("HBTARGET=#{target} bundle exec middleman server #{'--verbose' if BE_VERBOSE} #{'>/dev/null' if BE_QUIET}")

  else

    # Build each target.
    targets = targets.include?('all') ? valid_targets : targets

    targets.each do |target|
      puts_blue "Starting build for target '#{target}'…"

      result = system("HBTARGET=#{target} bundle exec middleman build #{'--verbose' if BE_VERBOSE} #{'>/dev/null' if BE_QUIET}")

      unless result
        puts_red "** NOTE: `middleman` did not exit cleanly for target '#{target}'. Build process will stop now."
        puts_red '   Consider using the --verbose flag to identify the source of the error. The error reported was:'
        puts_red "   #{$?}"
        exit 1
      end
    end

    puts_green '** ALL TARGETS COMPLETE **'

  end

  exit 0

end



##########################################################################
#  Middlemac Class
##########################################################################

class Middlemac < Middleman::Extension


#===============================================================
#  Configuration options
#   You do NOT have to change any of these. These are part of
#   the class. These options must be configured in config.rb.
#===============================================================

option :Target, 'default', 'The default target to process if not specified.'
option :CFBundleName, nil, 'The CFBundleName key; will be used in a lot of places.'
option :Help_Output_Location, nil, 'Directory to place the built helpbook.'
option :Targets, nil, 'A data structure that defines many characteristics of the target.'
option :Build_Markdown_Links, true, 'Whether or not to generate `_markdown-links.erb`'
option :Build_Markdown_Images, true, 'Whether or not to generate `_markdown-images.erb`'
option :Build_Image_Width_Css, true, 'Whether or not to generate `_image_widths.scss`'

option :File_Markdown_Images, '_markdown-images.erb', 'Filename for the generated images markdown file.'
option :File_Markdown_Links,  '_markdown-links.erb',  'Filename for the generated links markdown file.'
option :File_Image_Width_Css, '_image_widths.scss', 'Filename for the generated image width css file.'



#===============================================================
#  initializer
#===============================================================
def initialize(app, options_hash={}, &block)
  super
  app.extend ClassMethods

  # Ensure target exists. Value `options.Target` is supplied to middleman
  # via the HBTARGET environment variable, or the default set in config.rb.
  if options.Targets.key?(options.Target)
    puts "\n#{A_BLUE}Using target `#{options.Target}`#{A_RESET}"
  elsif options.Target == :improbable_value
    options.Targets.keys.each {|key| puts "#{key}"}
    exit 0
  else
    puts "\n#{A_RED}`#{options.Target}` is not a valid target. Choose from one of:#{A_CYAN}"
    options.Targets.keys.each {|key| puts "\t#{key}"}
    puts "#{A_RED}Or use nothing for the default target.#{A_RESET}"
    exit 1
  end

  #==============================================
  #  Callback before each page is rendered.
  #==============================================
  app.before do
    true
  end
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

  # Set the correct :build_dir based on the options.
  options.Help_Output_Location = File.dirname(__FILE__) unless options.Help_Output_Location
  app.set :build_dir, File.join(options.Help_Output_Location, "#{options.CFBundleName} (#{options.Target}).help", 'Contents')


  # Set the destinations for generated markdown partials and css.
  options.File_Markdown_Images = File.join(app.source, app.partials_dir, options.File_Markdown_Images)
  options.File_Markdown_Links  = File.join(app.source, app.partials_dir, options.File_Markdown_Links)
  options.File_Image_Width_Css = File.join(app.source, app.css_dir, options.File_Image_Width_Css)


  # create all other necessary files
  process_plists
  build_mdimages
  build_mdlinks
  build_imagecss

end #def


#===============================================================
#  before_build
#    Callback occurs one time before the build starts.
#    We will perform all of the required pre-work.
#===============================================================
def before_build

end

#===============================================================
#  after_build
#    Callback occurs one time after the build.
#    We will perform all of the finishing touches.
#===============================================================
def after_build
    run_help_indexer
end



#===============================================================
#  Sitemap manipulators.
#    Add new methods to each resource.
#===============================================================
def manipulate_resource_list(resources)

  resources.each do |resource|

    #--------------------------------------------------------
    # page_name
    #    Make page_name available for each page. This is the
    #    file base name. Useful for assigning classes, etc.
    #--------------------------------------------------------
    def resource.page_name
      File.basename( self.url, '.*' )
    end


    #--------------------------------------------------------
    #  page_group
    #    Make page_group available for each page. This is
    #    the source parent directory (not the request path).
    #    Useful for for assigning classes, and/or group
    #    conditionals.
    #--------------------------------------------------------
    def resource.page_group
      File.basename(File.split(self.source_file)[0])
    end


    #--------------------------------------------------------
    #  sort_order
    #    Returns the page sort order or nil.
    #      - If there's an `order` key, use it.
    #      - Otherwise if there's a three digit prefix.
    #      - Else nil.
    #--------------------------------------------------------
    def resource.sort_order
      if self.data.key?('order')
        self.data['order'].to_i
      elsif self.page_name[0..2].to_i != 0
        self.page_name[0..2].to_i
      else
        nil
      end
    end


    #--------------------------------------------------------
    #  valid_features
    #    Returns an array of valid features for this page
    #    based on the current target, i.e., features that
    #    are true for the current target. These are the
    #    only features that can be used with frontmatter
    #    :target or :exclude.
    #--------------------------------------------------------
    def resource.valid_features
      options = app.extensions[:Middlemac].options
      options.Targets[options.Target][:Features].select { |k, v| v }.keys
    end


    #--------------------------------------------------------
    #  targeted?
    #    Determines if this pages is eligible for inclusion
    #    in the current build/server environment based on:
    #      - is an HTML file, and
    #      - has a sort_order, and
    #      - if frontmatter:target is used, the target or
    #        feature appears in the frontmatter, and
    #      - if frontmatter:exclude is used, the target or
    #        enabled feature does NOT appear in the
    #        frontmatter.
    #--------------------------------------------------------
    def resource.targeted?
      target_name = app.extensions[:Middlemac].options.Target
      self.ext == '.html' &&
          self.data.key?('title') &&
          !self.sort_order.nil? &&
          ( !self.data['target'] || (self.data['target'].include?(target_name) || (self.data['target'] & self.valid_features).count > 0) ) &&
          ( !self.data['exclude'] || !(self.data['exclude'].include?(target_name) || (self.data['exclude'] & self.valid_features).count > 0) )
    end


    #--------------------------------------------------------
    #  brethren
    #    Returns an array of all of the siblings of the
    #    specified page, taking into account their
    #    eligibility for display.
    #      - is not already the current page, and
    #      - is targeted for the current build.
    #    Returned array will be:
    #      - sorted by sort_order.
    #--------------------------------------------------------
    def resource.brethren
      pages = self.siblings.find_all { |p| p.targeted? && p != app.current_page }
      pages.sort_by { |p| p.sort_order }
    end


    #--------------------------------------------------------
    #  brethren_next
    #    Returns the next sibling based on order or nil.
    #--------------------------------------------------------
    def resource.brethren_next
      if self.sort_order.nil?
        puts 'NEXT reports no sort order.'
        return nil
      else
        return self.brethren.select { |p| p.sort_order == app.current_page.sort_order + 1 }[0]
      end
    end


    #--------------------------------------------------------
    #  brethren_previous
    #    Returns the previous sibling based on order or nil.
    #--------------------------------------------------------
    def resource.brethren_previous
      if self.sort_order.nil?
        puts 'PREV reports no sort order.'
        return nil
      else
        return self.brethren.select { |p| p.sort_order == app.current_page.sort_order - 1 }[0]
      end
    end


    #--------------------------------------------------------
    #  navigator_eligible?
    #    Determine whether a page is eligible to include a
    #    previous/next page control based on:
    #      - the group is set to allow navigation (:navigate)
    #      - this page is not excluded from navigation. (:navigator => false)
    #      - this page has a sort_order.
    #--------------------------------------------------------
    def resource.navigator_eligible?
      (self.parent && self.parent.data.key?('navigate') && self.parent.data['navigate'] == true) &&
          !(self.data.key?('navigator') && self.data['navigator'] == false) &&
          (!self.sort_order.nil?)
    end


    #--------------------------------------------------------
    #  legitimate_children
    #    Returns an array of all of the children of the
    #    specified page, taking into account their
    #    eligibility for display.
    #      - is targeted for the current build.
    #    Returned array will be:
    #      - sorted by sort_order.
    #--------------------------------------------------------
    def resource.legitimate_children
      pages = self.children.find_all { |p| p.targeted? }
      pages.sort_by { |p| p.sort_order }
    end


    #--------------------------------------------------------
    #  breadcrumbs
    #    Returns an array of pages leading to the current
    #    page.
    #--------------------------------------------------------
    def resource.breadcrumbs
      hierarchy = [] << self
      hierarchy.unshift hierarchy.first.parent while hierarchy.first.parent
      hierarchy
    end


  end # .each

  resources
end


#===============================================================
#  Helpers
#    Methods defined in this helpers block are available in
#    templates.
#===============================================================

helpers do

  #--------------------------------------------------------
  # cfBundleIdentifier
  #   Returns the product `CFBundleIdentifier` for the
  #   current target
  #--------------------------------------------------------
  def cfBundleIdentifier
    options = extensions[:Middlemac].options
    options.Targets[options.Target][:CFBundleID]
  end


  #--------------------------------------------------------
  # cfBundleName
  #   Returns the product `CFBundleName` for the current
  #   target
  #--------------------------------------------------------
  def cfBundleName
    extensions[:Middlemac].options.CFBundleName
  end


  #--------------------------------------------------------
  # product_name
  #   Returns the ProductName for the current target
  #--------------------------------------------------------
  def product_name
    options = extensions[:Middlemac].options
    options.Targets[options.Target][:ProductName]
  end


  #--------------------------------------------------------
  # product_uri
  #   Returns the ProductURI for the current target
  #--------------------------------------------------------
  def product_uri
    options = extensions[:Middlemac].options
    options.Targets[options.Target][:ProductURI]
  end


  #--------------------------------------------------------
  # target_name
  #   Return the current build target.
  #--------------------------------------------------------
  def target_name
    extensions[:Middlemac].options.Target
  end


  #--------------------------------------------------------
  # target_name?
  #   Is the current target `proposal`?
  #--------------------------------------------------------
  def target_name?( proposal )
    extensions[:Middlemac].options.Target == proposal.to_sym
  end


  #--------------------------------------------------------
  # target_feature?
  #   Does the target have the feature `feature`?
  #--------------------------------------------------------
  def target_feature?( feature )
    options = extensions[:Middlemac].options
    features = options.Targets[options.Target][:Features]
    features.key?(feature) && features[feature]
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

    return unless options.Build_Markdown_Images

    puts "#{A_CYAN}Middlemac is creating `#{options.File_Markdown_Images}`.#{A_RESET}"

    files_array = []
    out_array = []
    longest_shortcut = 0
    longest_path = 0

    Dir.glob("#{app.source}/Resources/**/*.{jpg,png,gif}").each do |fileName|

        # Remove all file extensions and make a shortcut
        base_name = fileName
        while File.extname(base_name) != '' do
            base_name = File.basename( base_name, '.*' )
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

    File.open(options.File_Markdown_Images, 'w') { |f| out_array.each { |line| f.puts(line) } }

  end #def


  #--------------------------------------------------------
  #  build_mdlinks
  #    Will build a markdown file with shortcuts to links
  #    for every HTML file found in the project.
  #--------------------------------------------------------
  def build_mdlinks
    return unless options.Build_Markdown_Links

    puts "#{A_CYAN}Middlemac is creating `#{options.File_Markdown_Links}`.#{A_RESET}"

    files_array = []
    out_array = []
    longest_shortcut = 0
    longest_path = 0

    Dir.glob("#{app.source}/Resources/**/*.erb").each do |fileName|

        # Remove all file extensions and make a shortcut
        base_name = fileName
        while File.extname(base_name) != '' do
            base_name = File.basename( base_name, '.*' )
        end
        next if base_name.start_with?('_') # || base_name == 'index'

        if base_name == 'index'
          shortcut = "[#{File.split(File.split(fileName)[0])[1]}_index]:"

        else
          shortcut = "[#{base_name}]:"
        end

        # Make a fake absolute path
        path = Pathname.new(fileName).relative_path_from(Pathname.new(app.source))
        path = File::SEPARATOR + File.join(File.dirname(path), base_name) + '.html'

        # Get the title, if any
        metadata = YAML.load_file(fileName)
        title = (metadata.is_a?(Hash) && metadata.key?('title')) ? metadata['title'] : ''

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

    File.open(options.File_Markdown_Links, 'w') { |f| out_array.each { |line| f.puts(line) } }

  end #def


  #--------------------------------------------------------
  #  build_imagecss
  #    Builds a css file containing an max-width for every
  #    image in the project.
  #--------------------------------------------------------
  def build_imagecss
    return unless options.Build_Image_Width_Css

    puts "#{A_CYAN}Middlemac is creating `#{options.File_Image_Width_Css}`.#{A_RESET}"

    out_array = []

    Dir.glob("#{app.source}/Resources/**/*.{jpg,png,gif}").each do |fileName|
        # fileName contains complete path relative to this script.
        # Get just the name and extension.
        base_name = File.basename(fileName)

        # width
        if File.basename(base_name, '.*').end_with?('@2x')
          width = (FastImage.size(fileName)[0] / 2).to_i.to_s
        else
          width = FastImage.size(fileName)[0].to_s;
        end

        # proposed css
        out_array << "img[src$='#{base_name}'] { max-width: #{width}px; }"
    end

    File.open(options.File_Image_Width_Css, 'w') { |f| out_array.each { |line| f.puts(line) } }

  end #def


  #--------------------------------------------------------
  #  process_plists
  #    Performs substitutions in all _*.plist and
  #    _*.strings files in the project.
  #--------------------------------------------------------
  def process_plists

    Dir.glob("#{app.source}/**/_*.{plist,strings}").each do |fileName|

      puts "#{A_CYAN}Middlemac is processing plist file #{fileName}.#{A_RESET}"

        file = File.open(fileName)
        doc = Nokogiri.XML(file)
        file.close

        doc.traverse do |node|
          if node.text?
            node.content = node.content.gsub('{$CFBundleIdentifier}', options.Targets[options.Target][:CFBundleID])
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

      index_dir = File.expand_path(File.join(app.build_dir, 'Resources/', 'Base.lproj/' ))
      index_dst = File.expand_path(File.join(index_dir, "#{options.CFBundleName}.helpindex"))

      puts "#{A_CYAN}'#{index_dir}' #{A_BLUE}(indexing)#{A_RESET}"
      puts "#{A_CYAN}'#{index_dst}' #{A_BLUE}(final file)#{A_RESET}"

      `hiutil -Cf "#{index_dst}" "#{index_dir}"`
    else
      puts "#{A_RED}NOTE: `hiutil` is not on path or not installed. No index will exist for target '#{options.Target}'.#{A_RESET}"
    end
  end #def


#===============================================================
#  ClassMethods
#===============================================================

module ClassMethods

end #module


end #class


::Middleman::Extensions.register(:Middlemac, Middlemac)
