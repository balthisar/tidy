Middlemac, the Middleman Build System for Mac OS X Help Projects (README)
=========================================================================

version 1.0RC1, 2014-October-23
-------------------------------

_Middlemac_ is the specialized Apple HelpBook building system that uses the
tools of _Middleman_ to make building Apple HelpBooks for your Mac OS X
applications a snap. Whether you are targeting multiple versions of your
application or a single version, once properly (simply!) configured, _Middlemac_
will take all of the pain out of building Help files.

_Middlemac_ makes it simple to do this in Terminal…

`./middlemac target1 target2 target3`

…and end up with versions of your HelpBooks with all of the Apple-required files
in the Apple-required formats in the correct locations of your XCode build
directory. Simply build your help target, run your application, and find that
it just works!

At its simplest _Middlemac_ offers:

- Write your help files with plain text using the **Markdown** format (if you
  are reading this file in a text editor, this is an example of Markdown).
- Single or multiple build **targets**, e.g., your `pro` target can include
  content specific to the professional version of your application.
- **Features** support for each build target, e.g. each of your build targets
  can specify whether or not they support specific features, and this content
  will be included or excluded as your needs require.
- A low learning curve if you’re a developer.
- A set of conventions and tools that make automatic tables of contents,
  automatic sections, and automatic behavior effortless to implement.
- A basic, Apple-like CSS stylesheet and set of templates that can be used as-is
  or easily tweaked to suit your needs.


**Please note that _Middlemac_ is not associated in any way with the the team at
_Middleman_.**  


Getting Started
---------------

_Middlemac_’s documentation is included in the starter project (and more than
likely at [http://www.balthisar.com/manuals](http://www.balthisar.com/manuals)).
There are multiple ways you could be reading this content now, but for now we
will assume that you have not yet installed _Middlemac_ and its dependencies.

To get started and read the full documentation, make sure that your system has
[Ruby](https://www.ruby-lang.org/) installed (it comes pre-installed on Mac OS X
and some Linuxes), and follow these steps below. 

Note that this is untested on Windows.
{:.note}

Note that depending on your system’s setup you might have to prefix some of the
commands below with `sudo`. For example if the instruction is given as
`gem install bundler` and a permissions error is reported, you may probably
have to use `sudo gem install bundler` instead.
{:.note}

If you’re behind a proxy and haven’t already setup an `http-proxy` environment
variable, then that previous clause is a good hint and Google is your friend.
{:.note}


Quick version, if you don’t want to read details
------------------------------------------------

In your Terminal, do each of the following:

~~~ bash
xcode-select --install
gem install bundler
git clone http://github.com/balthisar/middlemac.git middlemac_demo
bundle install
./middlemac.rb --server free
open middlemac.webloc
~~~

If you’re on Linux and `open middlemac.webloc` command doesn’t work for you,
then use your preferred web browser and go to
[http://localhost:4567/Resources/Base.lproj/](http://localhost:4567/Resources/Base.lproj/).


Similar to above, with a bit of handholding
----------------------------------------

### Install XCode

If you’re on a Mac you’ll have to install XCode first, or at least the XCode
command line tools. You can _try_ just installing the tools first:

~~~ bash
xcode-select --install
~~~

If that fails or the rest of the installation fails, then install all of XCode.
It’s available in the App Store. It’s free of charge. And you’re using this
project to develop help for Mac OS X applications that you’re developing using
XCode anyway. Install it, already. Then you’ll have no dependency issues for the
rest of this procedure.

Dependencies on Linux are left up to you. Most modern Linuxes will prompt you to
install packages that are missing.
 
_Middlemac_ works quite well on Linux, but keep in mind that Linux doesn’t have
the help indexing tool that’s required in order to build a proper helpbook.
Other than for generating your final helpbook, Linux makes a fine development
environment.
{:.note} 


### Install bundler

[Bundler](http://bundler.io/) is the ubiquitous Ruby
[gem](http://guides.rubygems.org/what-is-a-gem/) management tool. You can
install if from your terminal easily:

`gem install bundler`

Ruby will download and install Bundler.


### Install the _middlemac_ project template

Although _Middlemac_ is a [_Middleman_](http://middlemanapp.com) extension, it’s
mostly a project template and distributed as such. Installation is as easy as:

`git clone http://github.com/balthisar/middlemac.git middlemac_demo`

Then `cd` into the `middlemac_demo` folder, and…


### Update gems (including _Middleman_ if needed)

Gems are Ruby programs and extensions. From within your project directory,
simply:

`bundle install`

This will cause several Ruby gems to begin downloading and install. Bundler
knows which gems to install (including _Middleman_ itself) because the file
`Gemfile` in this package contains the correct manifest.


### If you get “ERROR: failed to build gem native extension” (Mac OS X)

Try repeating the above using this command, instead:

`ARCHFLAGS=-Wno-error=unused-command-line-argument-hard-error-in-future bundle install`

The reasons are complex but if you really want to know, remember: Google is your
friend.

It appears that this issue is no longer present on Yosemite.


### Start the _Middleman_ server

_Middleman_ comes with its own HTTP server and requires no configuration. It
simply works, serving your helpbook as a website.

From the terminal, use _Middlemac_ to start the _Middleman_ server using our
`free` target:

`./middlemac.rb --server free`


### Open the site in your browser

Simply open the `middlemac.webloc` file from Finder to view the project results
in your default browser.

Or can open the bookmark file from Terminal with `open middleman.webloc`.

Or you prefer to open the help site manually, or if the .webloc file doesn’t
work on your Linux distro, you can go to
[http://localhost:4567/Resources/Base.lproj/](http://localhost:4567/Resources/Base.lproj/).

