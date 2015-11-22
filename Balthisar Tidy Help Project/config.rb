################################################################################
#  config.rb
#    Configure Middleman to generate Apple Helpbook containers for multiple
#    targets.
################################################################################

# 'middlemac.rb' contains the Middlemac class that will do additional work.
require 'middlemac'


################################################################
# Configuration. Change the option values to suit your needs.
################################################################

activate :Middlemac do |options|
  # You should only change the default, fall-back target here. This is the
  # target that will be processed if no environment variable is used,
  # e.g., if you run `middleman build` directly.
  options.Target = (ENV['HBTARGET'] || :pro).to_sym

  # This value will be used for correct .plists and .strings setup, and will
  # will determine final .help directory name. All targets will use the
  # same `CFBundleName`. Built targets will end up in `Help_Output_Location`
  # with the name `CFBundleName (target)`. This is *not* intended to be a
  # product name, which is defined individually for each target, further down.
  options.CFBundleName = 'Balthisar Tidy'

  # Directory where finished .help bundle should go. It should be relative
  # to this file, or make nil to leave in this help project directory. The
  # *actual* output directory will be an Apple Help bundle at this location
  # named in the form `#{CFBundleName} (target).help`. You might want to target
  # the `Resources` directory of you XCode project so that your XCode project is
  # always up to date.
  options.Help_Output_Location = '../Balthisar Tidy/Resources/'

  # Targets

  # NOTE: Ruby has a type of variable called a `symbol`, which are used below
  # quite extensively and look like :this_symbol. Except hey’re not really
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

  # :ProductName
  # You can specify different product names for each build target. The product
  # name for the current target will be available via the `product_name` helper.

  # :Features
  # A hash of features that a particular target supports or doesn't support.
  # The `has_feature` function and several helpers will use the true/false value
  # of these features in order to conditionally include content. This is given
  # as a hash of true/false instead of an array of symbols in order to make it
  # easier to enable/disable features for each target.

  options.Targets =
      {
          :web =>
              {
                  :CFBundleID     => 'com.balthisar.Balthisar-Tidy.web.help',
                  :ProductName    => 'Balthisar Tidy',
                  :ProductVersion => '3.0.0',
                  :ProductURI     => 'http://www.balthisar.com/',
                  :Features =>
                      {
                          :feature_advertise_pro        => true,
                          :feature_sparkle              => true,
                          :feature_exports_config       => false,
                          :feature_exports_rtf          => false,
                          :feature_supports_applescript => false,
                          :feature_supports_diffs       => false, # eventually.
                          :feature_supports_preview     => false, # eventually.
                          :feature_supports_extensions  => true,
                          :feature_supports_service     => true,
                          :feature_supports_SxS_diffs   => false,
                          :feature_supports_themes      => false,
                          :feature_supports_validation  => false,
                      }
              },

          :app =>
              {
                  :CFBundleID     => 'com.balthisar.Balthisar-Tidy.help',
                  :ProductName    => 'Balthisar Tidy',
                  :ProductVersion => '3.0.0',
                  :ProductURI     => 'http://www.balthisar.com/',
                  :Features =>
                      {
                          :feature_advertise_pro        => true,
                          :feature_sparkle              => false,
                          :feature_exports_config       => false,
                          :feature_exports_rtf          => false,
                          :feature_supports_applescript => false,
                          :feature_supports_diffs       => false, # eventually.
                          :feature_supports_preview     => false, # eventually.
                          :feature_supports_extensions  => true,
                          :feature_supports_service     => true,
                          :feature_supports_SxS_diffs   => false,
                          :feature_supports_themes      => false,
                          :feature_supports_validation  => false,
                      }
              },

          :pro =>
              {
                  :CFBundleID     => 'com.balthisar.Balthisar-Tidy.pro.help',
                  :ProductName    => 'Balthisar Tidy for Work',
                  :ProductVersion => '3.0.0',
                  :ProductURI     => 'http://www.balthisar.com/',
                  :Features =>
                      {
                          :feature_advertise_pro        => false,
                          :feature_sparkle              => false,
                          :feature_exports_config       => true,
                          :feature_exports_rtf          => true,
                          :feature_supports_applescript => true,
                          :feature_supports_diffs       => false, # eventually.
                          :feature_supports_preview     => false, # eventually.
                          :feature_supports_extensions  => true,
                          :feature_supports_service     => true,
                          :feature_supports_SxS_diffs   => false, # eventually.
                          :feature_supports_themes      => true,
                          :feature_supports_validation  => false, # eventually.
                      }
              },

      }


  # Build #{:partials_dir}/_markdown-links.erb file? This enables easy-to-use
  # markdown links in all markdown files, and is kept up to date.
  options.Build_Markdown_Links = true

  # Build #{:partials_dir}/_markdown-images.erb file? This enables easy-to-use
  # markdown links to images in all markdown files, and is kept up to date.
  options.Build_Markdown_Images = true

  # Build #{:css_dir}/_image_widths.scss? This will enable a max-width of
  # all images the reflect the image size. Images that are @2x will use
  # proper retina image width.
  options.Build_Image_Width_Css = true

  # Include automatic @2x images with srcset? If true then the image_tag
  # helper (including images specified in markdown) will will include a
  # srcset attribute if not already present. For example the image
  # image.png will be included in the srcset as "image@2x.png 2x".
  options.Retina_Srcset

  # These options are available but you should not change any of them if you
  # follow the conventions for Middlemac. Defaults are shown for reference.

  # Filename for the generated images markdown file.
  #options.File_Markdown_Images = '_markdown-images.erb'

  # Filename for the generated links markdown file.
  #options.File_Markdown_Links = '_markdown-links.erb'

  # Filename for the generated image width css file.
  #options.File_Image_Width_Css = '_image_widths.scss'

end #activate


################################################################
# STOP! There's nothing below here that you should have to
# change. Just follow the conventions and framework provided.
################################################################


#===============================================================
# Setup directories to mirror Help Book directory layout.
#===============================================================
set :source,       'Contents'
set :build_dir,    'Contents (build)'   # Will be overridden by MiddleMac.

set :fonts_dir,    'Resources/Base.lproj/assets/fonts'
set :images_dir,   'Resources/Base.lproj/assets/images'
set :js_dir,       'Resources/Base.lproj/assets/javascripts'
set :css_dir,      'Resources/Base.lproj/assets/stylesheets'

set :partials_dir, 'Resources/Base.lproj/assets/partials'
set :layouts_dir,  'Resources/Base.lproj/assets/_layouts'
set :data_dir,     'Contents/Resources/Base.lproj/assets/_data'


#===============================================================
# Ignore items we don't want copied to the destination
#===============================================================
#ignore 'data/*'


#===============================================================
# All of our links and assets must be relative to the file
# location, and never absolute. However we will *use* absolute
# paths with root being the source directory; they will be
# converted to relative paths at build.
#===============================================================
set :strip_index_file, false
set :relative_links, true
activate :relative_assets


#===============================================================
# Default to Apple-recommended HTML 4.01 layout.
#===============================================================
set :haml, :format => :html4
page 'Resources/Base.lproj/*', :layout => :'layout-html4'


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

  # no helpers here, but the Middlemac class offers quite a few.

end #helpers


################################################################################
# Build-specific configurations
################################################################################


#===============================================================
# :development - the server is running and watching files.
#===============================================================
configure :development do

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

  # Compass
  compass_config do |config|
    config.output_style = :expanded
    config.sass_options = { :line_comments => false }
  end

  # Minify js
  activate :minify_javascript

end #configure
