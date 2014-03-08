/**************************************************************************************************

	PreferenceController.m

	part of Balthisar Tidy

	The main preference controller. Here we'll control the following:

		o Handles the application preferences.
		o Implements class methods to be used before instantiation.


	The MIT License (MIT)

	Copyright (c) 2001 to 2013 James S. Derry <http://www.balthisar.com>

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 **************************************************************************************************/

#import <Cocoa/Cocoa.h>
#import "PreferenceController.h"
#import "JSDTidyDocument.h"

#if INCLUDE_SPARKLE == 1
#import <Sparkle/Sparkle.h>
#endif


#pragma mark - CATEGORY - Non-Public


@interface PreferenceController ()


#pragma mark - Properties

// Software Updater Pane Preferences and Objects
@property (nonatomic, weak) IBOutlet NSButton *buttonAllowUpdateChecks;
@property (nonatomic, weak) IBOutlet NSButton *buttonAllowSystemProfile;
@property (nonatomic, weak) IBOutlet NSPopUpButton * buttonUpdateInterval;

// Other Properties
@property (nonatomic, weak) IBOutlet NSView *optionPane;				// The empty pane in the nib that we will inhabit.

@property (nonatomic, strong) OptionPaneController *optionController;	// The real option pane loaded into optionPane.

@property (nonatomic, strong) JSDTidyDocument *tidyProcess;				// The optionController's tidy process.


@end


#pragma mark - IMPLEMENTATION


@implementation PreferenceController


#pragma mark - Class Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	sharedPreferences
		Implement this class as a singleton.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (id)sharedPreferences
{
    static PreferenceController *sharedMyPrefController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedMyPrefController = [[self alloc] init]; });
    return sharedMyPrefController;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	registerUserDefaults
		Register all of the user defaults. Implemented as a CLASS
		method in order to keep this with the preferences controller.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)registerUserDefaults
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	// Put all of the defaults in the dictionary
	defaultValues[JSDKeySavingPrefStyle] = @(kJSDSaveAsOnly);
	defaultValues[JSDKeyIgnoreInputEncodingWhenOpening] = @NO;
	defaultValues[JSDKeyFirstRunComplete] = @NO;
	
	// Get the defaults from the linked-in TidyLib
	[JSDTidyDocument addDefaultsToDictionary:defaultValues];
	
	// Register the defaults with the defaults system
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


#pragma mark - Initialization and Deallocation and Setup


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	init
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)init
{
	if (self = [super initWithWindowNibName:@"Preferences"])
	{
		[self setWindowFrameAutosaveName:@"PrefWindow"];
	}
	return self;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	dealloc
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:tidyNotifyOptionChanged
												  object:nil];
	_tidyProcess = nil;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	awakeFromNib
		- Create an |OptionPaneController| and put it
		  in place of the empty optionPane in the xib.
		- Setup Sparkle vs No-Sparkle.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void) awakeFromNib
{
	if (![self optionController])
	{
		self.optionController = [[OptionPaneController alloc] init];
	}
	
	[[self optionController] putViewIntoView:[self optionPane]];
	
	self.tidyProcess = [[self optionController] tidyDocument];

#if INCLUDE_SPARKLE == 0
	NSTabView *theTabView = [[self tabViewUpdates] tabView];
	[theTabView removeTabViewItem:[self tabViewUpdates]];
#else
	SUUpdater *sharedUpdater = [SUUpdater sharedUpdater];
	[[self buttonAllowUpdateChecks] bind:@"value" toObject:sharedUpdater withKeyPath:@"automaticallyChecksForUpdates" options:nil];
	[[self buttonUpdateInterval] bind:@"enabled" toObject:sharedUpdater withKeyPath:@"automaticallyChecksForUpdates" options:nil];
	[[self buttonUpdateInterval] bind:@"selectedTag" toObject:sharedUpdater withKeyPath:@"updateCheckInterval" options:nil];
	[[self buttonAllowSystemProfile] bind:@"value" toObject:sharedUpdater withKeyPath:@"sendsSystemProfile" options:nil];
#endif

}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	windowDidLoad
		Use the defaults to setup the correct preferences settings.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)windowDidLoad
{
	// Put the Tidy defaults into the |tidyProcess|.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[[self tidyProcess] takeOptionValuesFromDefaults:defaults];
	
	
	// NSNotifications from |optionController| indicate that one or more Tidy options changed.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidyOptionChange:)
												 name:tidyNotifyOptionChanged
											   object:[[self optionController] tidyDocument]];
}


#pragma mark - Events


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	handleTidyOptionChange
		We're here because we registered for NSNotification.
		One of the preferences changed in the option pane.
		We're going to record the preference, but we're not
		going to post a notification, because new documents
		will read the preferences themselves.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)handleTidyOptionChange:(NSNotification *)note
{
	[[self tidyProcess] writeOptionValuesWithDefaults:[NSUserDefaults standardUserDefaults]];
}

@end
