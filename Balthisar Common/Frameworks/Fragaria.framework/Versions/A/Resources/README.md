# MGSFragaria

A fork of https://github.com/KosmicTask/Fragaria with a focus on fixing bugs, while adding some new features along the way.

Have a look at the [ChangeLog](ChangeLog.md) to see what changed compared to the upstream MGSFragaria and across versions of this fork.

## What is it?

Fragaria is an OS X Cocoa syntax colouring `NSTextView` implemented within a framework named `MGSFragaria`. It supports a wide range of programming languages and includes preference panel support.

### Features

* Configurable syntax colouring
* Configurable font type, size and colour.
* Invisible character display
* Line numbering
* Brace matching and auto insertion
* Page guide
* Simple word auto complete
* Tab and indent control
* Line wrapping
* Configurable breakpoint marks
* Syntax error badges and underlines
* Drag and drop
* Split view support
* Support for custom application-specific parsers

## How do I use it?

The best way to learn how to use the framework is to look at the sample apps.

* __Fragaria Simple__ : a simple editor window that features language selection, a wired up text menu, and custom parsers.

* __Fragaria Doc__ : a simple `NSDocument` based editor with the new preferences panels.

* __Fragaria Complex__ : a split view editor with an hard-wired options panel

* __Fragaria Prefs__ : a split view editor like *Fragaria Complex* with the new preferences panels and more complex breakpoint marker behavior.

### Show me code

First, place `MGSFragariaView` in your nib. Then create an outlet for it in your window controller class, wiring the newly placed view to it. Alternatively you can create `MGSFragariaView` programmatically like any other view. Then, you can initialize Fragaria using its properties.

```obj-c
#import <Fragaria/Fragaria.h>

// Objective-C is the place to be
[fragaria setSyntaxDefinitionName:@"Objective-C"];

// set initial text
[fragaria setString:@"// We don't need the future."];
```

You can further customize the look of Fragaria by setting the appropriate properties. Have a look at [MGSFragariaView.h](MGSFragariaView.h) for detailed documentation.

### Breakpoint Highlighting

Use the `breakpointDelegate` property to define a breakpoint delegate that conforms to
`MGSBreakpointDelegate`. This delegate will act as a data source for the gutter view.

```obj-c
[fragaria setBreakpointDelegate:self];
```

If the delegates implements either `-colouredBreakpointsForFragaria:` or `-breakpointColourForLine:ofFragaria:`, you can set a custom color for your breakpoints. For example you can return a transparent `NSColor` for disabled breakpoints.

When the user clicks on a line number in the gutter, Fragaria sends the `-toggleBreakpointForFragaria:onLine:` message to the delegate, which will then update its breakpoint data. If you need to manually update the breakpoints, you should refresh the gutter view manually afterwards:

```obj-c
[fragaria reloadBreakpointData];
```

### Syntax Error Highlighting

To add clickable syntax error highlights define an `NSArray` of `MGSSyntaxError`s.

```obj-c
// define a syntax error
MGSSyntaxError *syntaxError = [[MGSSyntaxError new] autorelease];
syntaxError.errorDescription = @"Syntax errors can be defined";
syntaxError.line = 1;
syntaxError.character = 1;
syntaxError.length = 10;

fragaria.syntaxErrors = @[syntaxError];
```

You can specify a custom `warningLevel` to change the icon shown for the syntax error and its priority in case multiple syntax errors are assigned to the same line. To define custom priorities and icons you can subclass `MGSSyntaxError` and use the subclass.

### Using the new preference panels

The new preferences system allows for having multiple preference groups in the same apps, which can control all or some of the available options. Every `MGSFragariaView` that you want to be controlled by preferences must be added manually to a preference group; after you've done that, everything's automatic.

The easiest way to use the new preference panels is to only use the global group; this results in a single set of preferences for all the instances of Fragaria in the app, which is what you want 90% of the time.

To use the preference panels, first you must include the `FragariaDefaultsCoordinator` framework in your project in addition to the `Fragaria` framework.
Then, you set the persistent flag on the group when the application initializes. This is typically done by the application delegate inside `-applicationWillFinishLaunching:` (not in `-applicationDidFinishLaunching:` because other initialization code which uses the defaults controller may be called before `-applicationDidFinishLaunching:`)

```obj-c
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [[MGSUserDefaultsController sharedController] setPersistent:YES];
}
```

The global controller by default manages all the available properties of `MGSFragariaView`. If you want to manage some of these properties manually, you should also remove them from the managed properties set in this stage.

When you create a new `MGSFragariaView`, you can now register it to the global group in this way:

```obj-c
[[MGSUserDefaultsController sharedController] addFragariaToManagedSet:fragaria];
```

Before an `MGSFragariaView` registered to a defaults controller is deallocated, you should remove it from the controller's managed set. Not doing this may result in seemingly random crashes because the defaults controller does not retain the registered views (doing that would create a retain cycle).

```obj-c
[[MGSUserDefaultsController sharedController] removeFragariaFromManagedSet:fragaria];
```

Done this, to use the standard preference panels, you just use `MGSPrefsColourPropertiesViewController` and
`MGSPrefsEditorPropertiesViewController`. See [ApplicationDelegate.m](Applications/Doc/ApplicationDelegate.m) in the Fragaria Doc example to see how to use these view controllers with the popular preference panel library [MASPreferences](https://github.com/shpakovski/MASPreferences).

This feature is very new and still needs improvements, so it may change in potentially breaking ways.

### Custom colouring & parsing

There are three ways to customize colouring and parsing:

1. Creating a language syntax file used with the standard built-in parser
2. Creating a syntax parser class
   - from scratch
   - based on an existing parser class

#### Creating a language syntax file used with the standard built-in parser

To define a new syntax definition:

1. Generate a plist that defines the language syntax. 
2. Install the plist in the `Syntax Definitions` directory inside your application bundle's resources.

The plist structure is simple and browsing the [existing definitions](Fragaria/Additional%20Syntax%20Definitions) should provide 
some enlightenment. The plist keys are defined in [MGSClassicFragariaSyntaxDefinition.m](Fragaria/MGSClassicFragariaSyntaxDefinition.m). 

For much deeper insight see the  `-colour...InRange:withRangeScanner:documentScanner` methods in `MGSSyntaxColouring` and the detailed comments in [MGSClassicFragariaSyntaxDefinition.h](Fragaria/MGSClassicFragariaSyntaxDefinition.h).

#### Creating a syntax parser class

If you want to create just one parser that does not require additional configuration, simply create a new class which inherits from `MGSSyntaxParser` and implements the `MGSParserFactory` interface. As a template, you can use the ExampleCustomParser class from the [Fragaria Simple](Applications/Fragaria%20Simple) example.

In this use case, your parser will be a singleton which supports just one language.

The implementation of `-[MGSSyntaxParser parseForClient:]` will be the main entry point of your parser, where you put your parsing code.

If you want to base your parser on an existing one, just fetch the existing parser by name through the `-[MGSSyntaxController parserForSyntaxDefinitionName:]` method and call its `-parseForClient:` method before your parsing code.

For details, see the [Fragaria Simple](Applications/Fragaria Simple/) example and the documentation in [MGSSyntaxParser.h](Fragaria/MGSSyntaxParser.h), [MGSParserFactory.h](Fragaria/MGSParserFactory.h), [MGSSyntaxParserClient.h](Fragaria/MGSSyntaxParserClient.h) and [MGSSyntaxAwareEditor.h](Fragaria/MGSSyntaxAwareEditor.h).

## Where can I see it in use

The author of this fork is dog-feeding Fragaria in another project of his:

* [Tricky68k](https://github.com/shysaur/Tricky68k) : A tool for playing around with assembly language for the Motorola 68k CPU.

In the past, Fragaria has been used in the following projects and products (old links might be broken, and some project might have moved away from using Fragaria):

* [Appium Recorder](http://appium.io) : Appium is an open source, cross-platform test automation tool for native
  and hybrid mobile apps. ([repo](https://github.com/appium/appium)).

* [cocoa-rest-client](https://github.com/mmattozzi/cocoa-rest-client) A native OS X cocoa application for testing HTTP
  endpoints.

* [CocosBuilder](http://www.cocosbuilder.com/). CocosBuilder is a free tool (released under MIT-licence) for rapidly
  developing games and apps. ([repo](https://github.com/cocos2d/CocosBuilder))

* [Cocoduino](https://github.com/fabiankr/Cocoduino) is an IDE for the Arduino platform written in native Cocoa.

* [KosmicTask](http://www.mugginsoft.com) is a multi (20+) language  scripting environment for OS X that features
  script editing, network sharing, remote execution, and file processing.

* [nib2objc](https://github.com/akosma/nib2objc) This utility converts NIB files (or XIB ones) into Objective-C code

If you use Fragaria in your app and want it added to the list just let us know or edit the README.

### Supported languages

Fragaria supports syntax colouring for a wide range of programming languages and configuration file formats:

#### A
actionscript, 
actionscript3, 
active4d, 
ada, 
ampl, 
apache (config), 
apex,
applescript, 
asm-mips, 
asm-x86, 
asm-m68k,
asp-js, 
asp-vb, 
aspdotnet-cs, 
aspdotnet-vb, 
awk

#### B
batch (shell)

#### C
C, 
cobol, 
coffeescript, 
coldfusion, 
cpp, 
csharp, 
csound, 
css

#### D
D, 
dylan

#### E
eiffel, erl, eztpl

#### F
F-script,
fortran,
freefem

#### G
gedcom,
gnuassembler,
graphviz

#### H
haskell,
header,
html

#### I
idl

#### J
java,
javafx,
javascript,
jsp

#### L
latex,
lilypond,
lisp,
logtalk,
lsl,
lua

#### M
matlab,
mel,
metapost,
metaslang,
mysql,
nemerle,

#### N
nrnhoc


#### O
objectivec,
objectivecaml,
ox

#### P
pascal,
pdf,
perl,
php,
plist,
postscript,
prolog,
python

#### R
r,
rhtml,
ruby

#### S
scala,
sgml,
shell,
sml,
sql,
stata,
supercollider

#### T
tcltk,
torquescript

#### U
udo

#### V
vb,
verilog,
vhdl

#### X
xml


## How can I contribute
Take a look at the [TODO](TODO.md) list.

## Where did it come from?
Fragaria started out as the vital pulp of Smultron 3.4.1, which was open-sourced. Apart from Fragaria, the same code base was used to developed another text editor named Fraise, and the original author of Smultron has now resumed development.
