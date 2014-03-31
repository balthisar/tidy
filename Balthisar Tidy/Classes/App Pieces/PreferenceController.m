/**************************************************************************************************

	PreferenceController.m

	The main preference controller. Here we'll control the following:

	- Handles the application preferences.
	- Implements class methods to be used before instantiation.

	This controller parses `optionsInEffect.txt` in the application bundle, and compares
	the options listed there with the linked-in TidyLib to determine which options are
	in effect and valid. We use an instance of `JSDTidyModel` to deal with this.
 

	The MIT License (MIT)

	Copyright (c) 2001 to 2014 James S. Derry <http://www.balthisar.com>

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
#import "JSDTidyModel.h"

#if INCLUDE_SPARKLE == 1
#import <Sparkle/Sparkle.h>
#endif


#pragma mark - CATEGORY - Non-Public


@interface PreferenceController ()


#pragma mark - Properties


// Software Updater Pane Preferences and Objects
@property (nonatomic, weak) IBOutlet NSTabViewItem *tabViewUpdates;
@property (nonatomic, weak) IBOutlet NSButton *buttonAllowUpdateChecks;
@property (nonatomic, weak) IBOutlet NSButton *buttonAllowSystemProfile;
@property (nonatomic, weak) IBOutlet NSPopUpButton * buttonUpdateInterval;

// Other Properties
@property (nonatomic, weak) IBOutlet NSView *optionPane;				// The empty pane in the nib that we will inhabit.
@property (nonatomic, strong) OptionPaneController *optionController;	// The real option pane loaded into optionPane.


@end


#pragma mark - IMPLEMENTATION


@implementation PreferenceController


#pragma mark - Class Methods


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	sharedPreferences (class)
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
	registerUserDefaults (class)
		Register all of the user defaults. Implemented as a CLASS
		method in order to keep this with the preferences controller.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void)registerUserDefaults
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	/* Put all of the defaults in the new dictionary */

	/* Application preferences */
	[defaultValues setObject:@NO forKey:JSDKeyFirstRunComplete];
	[defaultValues setObject:@NO forKey:JSDKeyIgnoreInputEncodingWhenOpening];
	[defaultValues setObject:@(kJSDSaveAsOnly) forKey:JSDKeySavingPrefStyle];

	/* Preferences that apply to all open documents */
	[defaultValues setObject:@NO forKey:JSDKeyAllowMacOSTextSubstitutions];
	[defaultValues setObject:@YES forKey:JSDKeyOptionsAreGrouped];
	[defaultValues setObject:@NO forKey:JSDKeyOptionsBooleanUseCheckBoxes];
	[defaultValues setObject:@YES forKey:JSDKeyOptionsShowHumanReadableNames];

	/* Preferences for new or opening documents */
	[defaultValues setObject:@YES forKey:JSDKeyShowLikeFrontDocument];
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentDescription];
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentLineNumbers];
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentMessages];
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentTidyOptions];
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentSideBySide];
	[defaultValues setObject:@YES forKey:JSDKeyShowNewDocumentSyncInOut];


	// Get the defaults from the linked-in TidyLib
	// and register them with the defaults system.
	
	[JSDTidyModel addDefaultsToDictionary:defaultValues];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	[[NSUserDefaults standardUserDefaults] synchronize];
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
		_optionsInEffect = [JSDTidyModel loadConfigurationListFromResource:@"optionsInEffect" ofType:@"txt"];

		if (![[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyOptionsAreGrouped])
		{
			_optionsInEffect = [_optionsInEffect sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		}
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
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	awakeFromNib
		- Create an `OptionPaneController` and put it
		  in place of the empty optionPane in the xib.
		- Setup Sparkle vs No-Sparkle.
		- Give the OptionPaneController its optionsInEffect
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void) awakeFromNib
{
	if (![self optionController])
	{
		self.optionController = [[OptionPaneController alloc] init];
	}
			
	self.optionController.optionsInEffect = self.optionsInEffect;
	
	[[self optionController] putViewIntoView:[self optionPane]];
	

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
	// Put the Tidy defaults into the optionController.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[[[self optionController] tidyDocument] takeOptionValuesFromDefaults:defaults];
	
	
	// NSNotifications from |optionController| indicate that one or more Tidy options changed.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleTidyOptionChange:)
												 name:tidyNotifyOptionChanged
											   object:[[self optionController] tidyDocument]];
}


#pragma mark - Preferences Access Support via KVC


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	objectForKeyedSubscript:
		We will use this as a convenience accessor to the values
		for the application-wide preferences. Example:
	NSString *myVal = [PreferenceController sharedPreferences][mykey]
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (id)objectForKeyedSubscript:(id <NSCopying, NSObject>)key
{
	// Note: no checking for valid keys is performed. Always
	// use the constants so the compiler will flag mistakes.
	if ( [key isKindOfClass:[NSString class]])
	{
		return [[NSUserDefaults standardUserDefaults] objectForKey:(NSString*)key];
	}
	return nil;
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
	setObject:ForKeyedSubscript:
		We will use this as a convenience accessor to the values
		for the application-wide preferences. Example:
	NSString *myVal = [PreferenceController sharedPreferences][mykey]
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying, NSObject>)key
{
	// Note: no checking for valid keys is performed. Always
	// use the constants so the compiler will flag mistakes.
	if ( [key isKindOfClass:[NSString class]])
	{
		[[NSUserDefaults standardUserDefaults] setObject:obj forKey:(NSString*)key];
	}
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
	[[[self optionController] tidyDocument] writeOptionValuesWithDefaults:[NSUserDefaults standardUserDefaults]];
}

@end
