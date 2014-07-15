#!/usr/bin/env ruby

###############################################################################
# build_help.rb
#   This will build a Balthisar Tidy help book using the specified build
#   configuration.
#
#  - middleman output will be put into build_help.log.
#
# Usage:
#    build_help web
#    build_help app
#    build_help pro
#    build_help all
###############################################################################

require 'nokogiri'
require 'fileutils'


################################################################
# Configuration. Change these values to suit your needs.
################################################################

# This value will be used for correct .plists and .strings
# setup, and will determine finally .help directory name.
$CFBundleName = 'Balthisar Tidy'

# Location where finished .help build should go. It should be relative
# to this file, or make null to leave in this help project directory.
$HelpOutputLocation = "../Balthisar Tidy/Resources/"

# Different versions of your app should also have different bundle
# identifiers so that the correct version of your help files stays
# related to your app. Here is where you define the build targets
# as the hash key, and the desired CFBundleIdentifier as the value.
$CFBundleIDs = {
                 'web' => 'com.balthisar.web.free.balthisar-tidy.help',
                 'app' => 'com.balthisar.Balthisar-Tidy.help',
                 'pro' => 'com.balthisar.Balthisar-Tidy.pro.help',
                }

# @USER: search also for the string @USER in this file in order to
# find out where to set your feature specific ENV variables that
# will be available within your middleman source documents.


################################################################
# ANSI terminal codes for use in documentation string.
################################################################
aBlue      = "\033[34m"
aCyan      = "\033[36m"
aRed       = "\033[31m"
aReset     = "\033[0m"
aUnderline = "\033[4m"


################################################################
# Documentation. You should put the command line documentation
# here. Shown if neither a valid target nor all is specified.
################################################################
$documentation = <<-HEREDOC
#{aCyan}
   This tool generates a complete Apple Help Book using middleman as
   a static generator, and supports multiple build targets. It is
   necessary to specify one or more build targets.

   #{aUnderline}Usage:#{aReset}#{aCyan}
     build_help web     Build web version help.
     build_help app     Build app store free help.
     build_help pro     Build pro help.
     build_help all     Build everything.

   Also, any combination of web, app, pro, or all can be used to build
   multiple targets at the same time.

#{aReset}
HEREDOC


################################################################
# Private configuration. You shouldn't touch these. Just let
# the conventions work for you instead.
################################################################

$localSource = "Contents (source)/"
$localBuild = "Contents (build)/"

$titlepage_template = File.join($localSource, "Resources/", "Base.lproj/", "_title_page.html.md.erb")
$titlepage_destination = File.join($localSource, "Resources/", "Base.lproj/", "#{$CFBundleName}.html.md.erb")

$plist_template = File.join($localSource, "_Info.plist")
$plist_destination = File.join($localSource, "Info.plist")

$strings_template = File.join($localSource, "Resources/", "Base.lproj/", "_InfoPlist.strings")
$strings_destination = File.join($localSource, "Resources/", "Base.lproj/", "InfoPlist.strings")


################################################################
# Capture command line arguments.
################################################################

# lower-case everything and eliminate duplicate arguments
$targets = ARGV.map(&:downcase).uniq

# ensure each argument is valid, and fail if not
if $targets.count > 0
	$targets.each do |target|
		unless $CFBundleIDs.key?(target) || target == "all"
			STDOUT.puts $documentation
			exit 1
		end
	end
else
	# no arguments isn't a failure.
	STDOUT.puts $documentation
	exit 0
end


################################################################
# Process the build targets.
################################################################

if $targets.include? "all"
	$CFBundleIDs.each { |key, value| processOneTarget key }
else
	$targets.each { |key| processOneTarget key }
end

outpGreen "\n** ALL TARGETS COMPLETE **\n"

exit 0

###############################################################################
# METHODS, enclosed in a BEGIN block in order to facilitate "late" method
# declarations. Access to globals is allowed, and since this is just a script
# and not real software engineering, I will allow it.
###############################################################################

BEGIN {

	#################################################
	# Output in color and abstract standard out.
	#################################################
	def outpBlue(string)
		STDOUT.puts "\033[34m" + string + "\033[0m"
	end
	def outpCyan(string)
		STDOUT.puts "\033[36m" + string + "\033[0m"
	end
	def outpGreen(string)
		STDOUT.puts "\033[32m" + string + "\033[0m"
	end
	def outpRed(string)
		STDOUT.puts "\033[31m" + string + "\033[0m"
	end
	def outpYellow(string)
		STDOUT.puts "\033[33m" + string + "\033[0m" # really ANSI brown
	end


	#################################################
	# processOneTarget processes `localTarget`
	#################################################
	def processOneTarget(localTarget)

		#--------------------------------------------
		# Define Remaining Variables. Note that the
		# ENV variables are available within your
		# middleman documents.
		#--------------------------------------------

		$CFBundleIdentifier = $CFBundleIDs[localTarget]
		$FinalOutput = File.join($HelpOutputLocation, "#{$CFBundleName} (#{localTarget}).help")

		ENV['CFBundleName'] = $CFBundleName
		ENV['CFBundleIdentifier'] = $CFBundleIdentifier
		ENV['HelpBookTarget'] = localTarget

		#--------------------------------------------
		# Announce our intentions
		#--------------------------------------------
		outpBlue "\nBEGINNING TARGET '#{localTarget}'"
		outpCyan "  CFBundleName       = #{$CFBundleName}"
		outpCyan "  CFBundleIdentifier = #{$CFBundleIdentifier}."

		#--------------------------------------------
		# @USER: Feature Specific ENVironment vars.
		# You can set these to anything that you
		# want based on the conditions that you
		# want. Remember that they must be string
		# representations, not true booleans.
		#--------------------------------------------

		ENV['feature_advertise_pro']        = (localTarget == "web" || localTarget == "app") ? "yes" : "no"
		ENV['feature_sparkle']              = (localTarget == "web") ? "yes" : "no"
		ENV['feature_exports_config']       = (localTarget == "pro") ? "yes" : "no"
		ENV['feature_supports_applescript'] = (localTarget == "pro") ? "yes" : "no"
		ENV['feature_supports_diffs']       = "no" # will be implemented for ALL
		ENV['feature_supports_preview']     = "no" # will be implemented for ALL
		ENV['feature_supports_extensions']  = "no" # (localTarget == "pro") ? "yes" : "no"
		ENV['feature_supports_service']     = "no" # (localTarget == "pro") ? "yes" : "no"
		ENV['feature_supports_SxS_diffs']   = "no" # (localTarget == "pro") ? "yes" : "no"
		ENV['feature_supports_validation']  = "no" # (localTarget == "pro") ? "yes" : "no"


		#--------------------------------------------
		# Process the .plist and .strings.
		#--------------------------------------------

		# open and check existance of files.
		unless File::exists?($plist_template)
			outpRed "\n   * Expected to find the .plist template: #{$plist_template}, but didn't. Exiting.\n\n"
			exit 1
		end

		unless File::exists?($strings_template)
			outpRed "\n   * Expected to find the .strings template: #{$strings_template}, but didn't. Exiting.\n\n"
			exit 1
		end

		# Process the .plist
		outpCyan "Processing the .plist..."
		$file = File.open($plist_template)
		$doc = Nokogiri.XML($file)
		$file.close

		#puts $doc.to_xml(:indent => 2)
		$doc.traverse do |node|
			if node.text?
				node.content = node.content.gsub('{$CFBundleIdentifier}', $CFBundleIdentifier)
				node.content = node.content.gsub('{$CFBundleName}', $CFBundleName)
			end
		end
		#puts $doc.to_xml(:indent => 2)

		File.open($plist_destination,'w') {|f| $doc.write_xml_to f}


		# Process the .strings
		outpCyan "Processing the .strings..."
		$file = File.open($strings_template)
		$doc = Nokogiri.XML($file)
		$file.close

		#puts $doc.to_xml(:indent => 2)
		$doc.traverse do |node|
			if node.text?
				node.content = node.content.gsub('{$CFBundleIdentifier}', $CFBundleIdentifier)
				node.content = node.content.gsub('{$CFBundleName}', $CFBundleName)
			end
		end
		#puts $doc.to_xml(:indent => 2)

		File.open($strings_destination,'w') {|f| $doc.write_xml_to f}


		#--------------------------------------------
		# Make the title page.
		#--------------------------------------------
		FileUtils.cp($titlepage_template, $titlepage_destination)

		#--------------------------------------------
		# Run middleman.
		#--------------------------------------------

		outpCyan "Building content with middleman..."

		`bundle exec middleman build --verbose 2>&1 >build_help.log`
		unless $?.success?
			outpRed "\n   * NOTE: `middleman` did not exit cleanly for target '#{localTarget}'. Build process will stop now.\n\n"
			exit 1
		end


		#--------------------------------------------
		# Run hiutil.
		#--------------------------------------------

		outpCyan "Looking for the help indexer..."

		`command -v hiutil > /dev/null`
		if $?.success?
            $indexDir = File.join($localBuild, "Resources/", "Base.lproj")
            $indexDst = File.join($indexDir, "#{$CFBundleName}.helpindex")

            outpCyan "Help indexer is indexing '#{$indexDir}' and index will be placed in '#{$indexDst}'."

            `hiutil -Cf "#{$indexDst}" "#{$indexDir}"`
		else
			outpYellow "\n   - NOTE: `hituil` is not on path or not installed. A new help index will NOT be generated for target '#{localTarget}'.\n"
		end


		#--------------------------------------------
		# Setup the final help directory.
		#--------------------------------------------

		outpCyan "Assembling the project output into #{$FinalOutput}..."

		Dir.mkdir($FinalOutput) unless File.directory?($FinalOutput)
		FileUtils.copy_entry($localBuild, File.join($FinalOutput, "Contents"),false,false,true)

		outpBlue "Building '#{$FinalOutput}' is complete."

	end #processOneTarget

} #block
