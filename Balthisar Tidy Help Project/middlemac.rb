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
This tool generates a complete Apple Help Book using Middleman as
a static generator, and supports multiple build targets. It is
necessary to specify one or more build targets.

  Use:
#{targets_array.sort.collect { |item| "    middlemac #{item}"}.join("\n")}
    middlemac all

Also, any combination of #{targets_array.join(', ')} or all can be used to build
multiple targets at the same time.

  Switches:
    -v, --verbose    Executes Middleman in verbose mode for each build target.
    -q, --quiet      Silences Middleman output, even if --verbose is specified.
    -s, --server     Runs Middleman in server mode. Server target is undefined if more than one or all is specified!
    -h, --help       Displays this help and doesn’t process files or run server.

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
option :Retina_Srcset, true, 'Whether or not to generate srcset attributes automatically.'

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
    puts_blue "\nUsing target `#{options.Target}`"
  elsif options.Target == :improbable_value
    options.Targets.keys.each {|key| puts "#{key}"}
    exit 0
  else
    puts_red "\n`#{options.Target}` is not a valid target. Choose from one of:"
    options.Targets.keys.each {|key| puts "\t#{key}"}
    puts_red "Or use nothing for the default target."
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
    cleanup_nontarget_files
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
  # product_version
  #   Returns the ProductVersion for the current target
  #--------------------------------------------------------
  def product_version
    options = extensions[:Middlemac].options
    options.Targets[options.Target][:ProductVersion]
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


  #--------------------------------------------------------
  # image_tag
  #   Override the built-in version in order to support
  #   automatic @2x assets.
  #--------------------------------------------------------
  def image_tag(path, params={})
    params.symbolize_keys!

    # We'll use these for different purposes below.
    file_name = File.basename( path )
    file_base = File.basename( path, '.*' )
    file_extn = File.extname( path )
    file_path = File.dirname( path )

    # Here's we're going to log missing images, i.e., images that
    # were requested for for which no file was found. Note that this
    # won't detect images requested via md ![tag][reference].
    checking_path = File.join(source_dir, path)
    unless File.exist?( checking_path )
      puts_red "#{file_name} was requested but is not in the source!"
    end

    # Here we're going to automatically substitute a target-specific image
    # if the specified image includes the magic prefix `all-`. We have to
    # make this check prior to the srcset below, so that srcset can check
    # for the existence of the correct, target-specific file we determine
    # here.
    if file_name.start_with?("all-")
      proposed_name = file_name.sub("all-", "#{target_name}-")
      checking_path = File.join(source_dir, file_path, proposed_name)

      if File.exist?( checking_path )
        file_name = proposed_name
        file_base = File.basename( file_name, '.*' )
        path = file_name
      end
    end

    # Here we're going to automatically include an @2x image in <img> tags
    # as a `srcset` attribute if there's not already a `srcset` present.
    if extensions[:Middlemac].options.Retina_Srcset

      unless params.key?(:srcset)
          proposed_name = "#{file_base}@2x#{file_extn}"
          checking_path = File.join(source_dir, file_path, proposed_name)

          if File.exist?( checking_path )
            srcset_img = File.join(file_path, "#{file_base}@2x#{file_extn} 2x")
            params[:srcset] = srcset_img
          end
      end

    end # if extensions

    super(path, params)
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

    puts_cyan "Middlemac is creating `#{options.File_Markdown_Images}`."

    files_array = []
    out_array = []
    longest_shortcut = 0

    Dir.glob("#{app.source}/Resources/**/*.{jpg,png,gif}").each do |fileName|

        # Remove all file extensions and make a shortcut
        base_name = fileName
        while File.extname(base_name) != '' do
            base_name = File.basename( base_name, '.*' )
        end
        next if base_name.start_with?('_')
        shortcut = "#{base_name}"

        # Make a fake absolute path `/Resources/...`. Middleman will convert
        # these to appropriate relative paths later, and this will just
        # magically work in the helpbooks. 
        path = File::SEPARATOR + Pathname.new(fileName).relative_path_from(Pathname.new(app.source)).to_s

        files_array << { :shortcut => shortcut, :path => path }

        # We will format the destination file nicely with spaces.
        # +3 to account for bracketing []:
        longest_shortcut = shortcut.length + 3 if shortcut.length + 3 > longest_shortcut

    end

    files_array = files_array.uniq.sort_by { |key| [File.split(key[:path])[0], key[:path]] }
    
    # Now add virtual `all-` items for target-specific items for which no `all-` exists.
    # Middlemac will intelligently support target-specific image files, but it will
    # never have the chance unless a markdown reference is present in this file. Of
    # course this only applies if you're using reference notation.
    options.Targets.keys.each do |target|
    
        # Build an array of all files starting with `target-`
        current_set = files_array.select { |item| item[:shortcut].start_with?("#{target.to_s}-") }
        
        # For each of these items, check to see if `all-` exists.
        current_set.each do |item|
        
            seek_for = item[:shortcut].sub("#{target.to_s}-", "all-")
            unless files_array.any? { |hash| hash[:shortcut] == seek_for }
   			    path = item[:path].sub("#{target.to_s}-", "all-")
   			    files_array << { :shortcut => seek_for, :path => path }
   			end
        end
    end

    # Create the actual output from the files_array.
    files_array.each do |item|
        # Just a reminder to myself that this is a format string. 
        shortcut_out = "%-#{longest_shortcut}.#{longest_shortcut}s" % "[#{item[:shortcut]}]:"
        out_array << "#{shortcut_out}  #{item[:path]}"
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

    puts_cyan "Middlemac is creating `#{options.File_Markdown_Links}`."

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

    puts_cyan "Middlemac is creating `#{options.File_Image_Width_Css}`."

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

      puts_cyan "Middlemac is processing plist file #{fileName}."

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
  #  cleanup_nontarget_files
  #    We support substituting target-specific files when
  #    present in place of files prefixed with `all-`,
  #    and we want to ensure that other targets' files
  #    aren't included in the output.
  #    @TODO: We really do need to delete an all- file
  #           for which a target- file exists.
  #--------------------------------------------------------
  def cleanup_nontarget_files

    delete_dir = File.expand_path(File.join(app.build_dir, 'Resources/', 'Base.lproj/', 'assets/', 'images/'))

    puts_blue "Cleaning up excess image files from target '#{options.Target}'"
    puts_red "Images for the following targets are being deleted from the build directory:"

    (options.Targets.keys - [options.Target]).each do |target|

      puts_red "#{target.to_s}"
      Dir.glob("#{delete_dir}/**/#{target}-*.{jpg,png,gif}").each do |f|
        puts_red " Deleting #{File.basename(f)}"
        File.delete(f)
      end
    end

    puts_red "\nImages prefixed all- are being deleted if a corresponding #{options.Target}- exists."

    Dir.glob("#{delete_dir}/**/all-*.{jpg,png,gif}").each do |f|
      if File.exist?( f.sub("all-", "#{options.Target}-") )
        puts_red " Deleting #{File.basename(f)}"
        File.delete(f)
      end
    end


  end


  #--------------------------------------------------------
  #  run_help_indexer
  #--------------------------------------------------------
  def run_help_indexer

    # see whether a help indexer is available.
    `command -v hiutil > /dev/null`
    if $?.success?

      index_dir = File.expand_path(File.join(app.build_dir, 'Resources/', 'Base.lproj/' ))
      index_dst = File.expand_path(File.join(index_dir, "#{options.CFBundleName}.helpindex"))

      puts_cyan "'…#{index_dir.split(//).last(50).join}' (indexing)"
      puts_cyan "'…#{index_dst.split(//).last(50).join}' (final file)"

      `hiutil -Cf "#{index_dst}" "#{index_dir}"`
    else
      puts_red "NOTE: `hiutil` is not on path or not installed. No index will exist for target '#{options.Target}'."
    end
  end #def


#===============================================================
#  ClassMethods
#===============================================================

module ClassMethods

end #module


end #class


::Middleman::Extensions.register(:Middlemac, Middlemac)
