################################################################################
#  config.rb
#    Configure Middleman to generate Apple HelpBook containers for multiple
#    targets.
################################################################################

##########################################################################
# Build System Integration
#  If built from Xcode (or another build system you create), then setup
#  some of our variables automatically from the environment variables
#  that the build system sets for us. You’ll have to set up Xcode to
#  set this environment variable, of course.
##########################################################################
version_app = ENV.has_key?('TIDY_CFBundleShortVersionString') ? ENV['TIDY_CFBundleShortVersionString'] : '4.1.0'


##########################################################################
# Targets Configuration
#  Middlemac is capable of building multiple targets for variants of your
#  application using the `middleman-targets` gem. Activate it and change
#  the option values here to suit your needs. Note that middleman-targets
#  adds configuration parameters to the base Middleman application; these
#  are *not* extension options.
##########################################################################
activate :MiddlemanTargets

# Set the default target, i.e, the target that is used automatically when you
# `middleman build` or `middleman server` without the `targets` CLI option.
config[:target] = :pro

# Targets

# NOTE: Ruby has a type of variable called a `symbol`, which are used below
# quite extensively and look like :this_symbol. Except they’re not really
# variables; you can’t assign values to them. Their value is themselves,
# though they have useful string representations (:this_symbol.to_s). You
# can even get the symbol representation of this_string.to_sym. Because
# they're unique, they make excellent array/hash keys and excellent,
# guaranteed unique values.

# :CFBundleID
# Just as different versions of your app must have different bundle identifiers
# so the OS can distinguish them, their help files must have unique bundle IDs,
# too. Your application specifies the help file `CFBundleID` in its
# `CFBundleHelpBookName` entry. Therefore for each target, ensure that your
# application has a `CFBundleHelpBookName` that matches the `CFBundleID` that
# you will set here.

# :HPDBookIconPath
# If specified a target-specific icon will be used as the help book icon by
# Apple’s help viewer. This path must be relative to the location of the
# `Resources` directory per Apple’s specification. If `nil` (or not present) 
# then the default `SharedGlobalAssets/convention/icon_32x32@2x.png` will be
# used.

# :CFBundleName
# This value will be used for correct .plists and .strings setup, and will
# determine final .help directory name. All targets should use the same
# :CFBundleName. Built targets will be named `CFBundleName_(target).help`.
# This is *not* intended to be a product name, which is defined below.

# :ProductName
# You can specify different product names for each build target. The product
# name for the current target will be available via the `product_name` helper.

# :ProductVersion
# You can specify different product versions for each build target. The
# product version for the current target will be available via the
# `product_version` helper.

# :ProductURI
# You can specify different product URIs for each build target. The URI
# for the current target will be available via the `product_uri` helper.

# :ProductCopyright
# You should specify a copyright string to be included in the Apple Help Book.
# This typically appears when you print a Help Book.

# (other)
# You can specify additional .plist and .strings keys here, too. Have a look
# at `Info.plist.erb` and `InfoPlist.strings.erb`; simply use the exact key
# name and they will be supported. This is probably unneeded unless you are
# implementing advanced help book features.

# :Features
# A hash of features that a particular target supports or doesn't support.
# The `has_feature` function and several helpers will use the true/false value
# of these features in order to conditionally include content.

config[:targets] = {
        :web =>
            {
                :CFBundleID      => 'com.balthisar.Balthisar-Tidy.web.help',
                :HPDBookIconPath => nil,
                :CFBundleName    => 'Balthisar Tidy',
                :ProductName     => 'Balthisar Tidy',
                :ProductVersion  => version_app,
                :ProductURI      => 'http://www.balthisar.com/',
                :ProductCopyright => '© 2018 Jim Derry. All rights reserved.',
                :features =>
                    {
                        :feature_advertise_pro        => true,
                        :feature_sparkle              => true,
                        :feature_exports_config       => false,
                        :feature_exports_rtf          => false,
                        :feature_supports_applescript => false,
                        :feature_supports_diffs       => false, # eventually.
                        :feature_supports_extensions  => true,
                        :feature_supports_service     => true,
                        :feature_supports_SxS_preview => false,
                        :feature_supports_SxS_diffs   => false,
                        :feature_supports_themes      => false,
                    }
            },

        :app =>
            {
                :CFBundleID      => 'com.balthisar.Balthisar-Tidy.help',
                :HPDBookIconPath => nil,
                :CFBundleName    => 'Balthisar Tidy',
                :ProductName     => 'Balthisar Tidy',
                :ProductVersion  => version_app,
                :ProductURI      => 'http://www.balthisar.com/',
                :ProductCopyright => '© 2018 Jim Derry. All rights reserved.',
                :features =>
                    {
                        :feature_advertise_pro        => true,
                        :feature_sparkle              => false,
                        :feature_exports_config       => false,
                        :feature_exports_rtf          => false,
                        :feature_supports_applescript => false,
                        :feature_supports_diffs       => false, # eventually.
                        :feature_supports_extensions  => true,
                        :feature_supports_service     => true,
                        :feature_supports_SxS_preview => false,
                        :feature_supports_SxS_diffs   => false,
                        :feature_supports_themes      => false,
                    }
            },

        :pro =>
            {
                :CFBundleID      => 'com.balthisar.Balthisar-Tidy.pro.help',
                :HPDBookIconPath => nil,
                :CFBundleName    => 'Balthisar Tidy',
                :ProductName     => 'Balthisar Tidy for Work',
                :ProductVersion  => version_app,
                :ProductURI      => 'http://www.balthisar.com/',
                :ProductCopyright => '© 2018 Jim Derry. All rights reserved.',
                :features =>
                    {
                        :feature_advertise_pro        => false,
                        :feature_sparkle              => false,
                        :feature_exports_config       => true,
                        :feature_exports_rtf          => true,
                        :feature_supports_applescript => true,
                        :feature_supports_diffs       => false, # eventually.
                        :feature_supports_extensions  => true,
                        :feature_supports_service     => true,
                        :feature_supports_SxS_preview => true,
                        :feature_supports_SxS_diffs   => false, # eventually.
                        :feature_supports_themes      => true,
                    }
            },

    } # targets

# By enabling :target_magic_images, target specific images will be used instead
# of the image you specify if it'ss prefixed with :target_magic_word. For
# example, you might request "all-my_image.png", and "pro-my_image.png" (if it
# exists) will be used in your :pro target instead.
#
# Important: when this is enabled, images from *other* targets will *not* be
# included in the build! In the example above, *any* image prefixed with "free-"
# would not be included in the output directory.
config[:target_magic_images] = true
config[:target_magic_word] = 'all'


################################################################
# Configuration
#  Change the option values to suit your needs.
################################################################
activate :Middlemac do |options|

  # Directory where finished .help bundle should go. It should be relative
  # to this file, or make nil to leave in this help project directory. The
  # *actual* output directory will be an Apple Help bundle at this location
  # named in the form `#{CFBundleName} (target).help`. You might want to target
  # the `Resources` directory of your XCode project so that your XCode project
  # is always up to date.
  options.help_output_location = '../Balthisar Tidy/Resources'

  # If set to true, then the enhanced image_tag helper will be used
  # to include @2x, @3x, and @4x srcset automatically, if the image assets
  # exist.
  options.retina_srcset = true

  # If set to an array of possible image extension values, then the `image_tag`
  # helper will work for images even if you don't specify an extension, but only
  # if a file exists in the sitemap that has one of these extensions. Set this to
  # an array of extensions in the order of precedence.
  options.img_auto_extensions = %w(.svg .png .jpg .jpeg .gif .tiff .tif)

  # If set to true, some of the templates will show additional information
  # when pages are generated, such as contents of md_links and md_images.
  # Also, JavaScript redirects will be omitted from naked pages, and the
  # meta refresh will be set to 100 seconds for such pages.
  options.show_debug = false

  # If set to true, Apple will provide next page and previous page navigation
  # gadgets automatically at the bottom of each content page. Apple itself
  # does not use this feature currently.
  options.show_previous_next = false

  # Indicate whether or not numeric file name prefixes used for sorting
  # pages should be eliminated during output. This results in cleaner
  # URI's. Helpers such as `page_name` and Middleman helpers such as
  # `page_class` will reflect the pretty name.
  config.strip_file_prefixes = true

end #activate


################################################################
# STOP! There's nothing below here that you should have to
# change. Just follow the conventions and framework provided.
################################################################


#===============================================================
# Setup directories to mirror Help Book directory layout.
#===============================================================
set :source,         'Contents'
set :data_dir,       'Contents/Resources/SharedGlobalAssets/_data'
set :assets_dir,     'Resources/SharedGlobalAssets'
set :partials_dir,   '_partials'
set :layouts_dir,    '_layouts'
set :convention_dir, 'convention'
set :css_dir,        'css'
set :fonts_dir,      'fonts'
set :images_dir,     'images'
set :js_dir,         'js'


#===============================================================
# Other required setup. Note: don't use relative assets or
# links here, as Apple require very specific hrefs.
#===============================================================
set :strip_index_file, false


#===============================================================
# Default to HTML5 Layout.
#===============================================================
Haml::TempleEngine.disable_option_validator!
set :haml, :format => :html5
page 'Resources/*.lproj/*.html', :layout => :'layout-apple-modern'
page 'Resources/*.lproj/asides/*.html', :layout => :'layout-apple-modern-aside'


#===============================================================
# Add-on features
#===============================================================
activate :syntax


################################################################################
# Helpers
################################################################################


#===============================================================
# Methods defined in this helpers block are available in
# templates.
#===============================================================
helpers do

  # Use this to prepare for the migration to "macOS" from "Mac OS X".
  def mac_os
    'macOS'
  end
  
  # Use this to return the product name with non-breaking spaces.
  def pn
    product_name.gsub(/ /, '&nbsp;');
  end
  
  # Use this to return the product name emphasized.
  def pne
    "<em>#{pn}</em>"
  end
  
end #helpers


################################################################################
# Build-specific configurations
################################################################################


#===============================================================
# :server - the server is running and watching files.
#===============================================================
configure :server do

  # Reload the browser automatically whenever files change
  activate :livereload, :host => '127.0.0.1'

  compass_config do |config|
    config.output_style = :expanded
    config.sass_options = { :line_comments => true }
  end

end #configure


#===============================================================
# :build - build is executed specifically.
#===============================================================
configure :build do

  compass_config do |config|
    config.output_style = :expanded
    config.sass_options = { :line_comments => false }
  end

end #configure
