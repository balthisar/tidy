/**************************************************************************************************

	ValidatorOptionsViewController
	 
	Copyright © 2003-2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "ValidatorOptionsViewController.h"
#import "CommonHeaders.h"
#import "NSImage+Tinted.h"
#import "JSDCollapsingView.h"

@import JSDNuVFramework;


@interface ValidatorOptionsViewController ()

/* We need access to this view to make layout updates. */
@property (nonatomic, assign) IBOutlet NSView *serviceView;

/* We want the delegate method to know which control is knocking. */
@property (nonatomic, assign) IBOutlet NSTextField *fieldCustomServer;

/* Some convenient shortcut properties. */
@property (nonatomic, assign, readonly) NSString *urlBuiltIn;
@property (nonatomic, assign, readonly) NSString *urlW3C;
@property (nonatomic, assign, readonly) NSString *urlCustom;

/* Remember the current tag for property use. */
@property (nonatomic, assign, readwrite) NSInteger currentTag;

/* Label text for the built-in server label. */
@property (nonatomic, assign, readonly) NSImage *statusBuiltIn;
@property (nonatomic, assign, readwrite) NSString *statusBuiltInHint;

@end


@implementation ValidatorOptionsViewController


#pragma mark - Initialization and Destruction


/*———————————————————————————————————————————————————————————————————*
 * init
 *———————————————————————————————————————————————————————————————————*/
- (id)init
{
    return [super initWithNibName:@"ValidatorOptionsViewController" bundle:nil];
}


/*———————————————————————————————————————————————————————————————————*
 * - awakeFromNib
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
	self.view.wantsLayer = YES;
	self.serviceView.wantsLayer = YES;

	JSDValidatorSelectionType selection = [[NSUserDefaults standardUserDefaults] integerForKey:JSDKeyValidatorSelection];

	if ( selection < JSDValidatorUndefined || selection > JSDValidatorCustom )
	{
		selection = JSDValidatorBuiltIn;
	}

	self.currentTag = selection;

	NSButton *selected = nil;

	if ( (selected = [self.view viewWithTag:selection]) )
	{
		selected.state = NSOnState;
		[self radioAction:selected];
		[self.view layoutSubtreeIfNeeded];
	}
}


#pragma mark - Action Methods


/*———————————————————————————————————————————————————————————————————*
 * - radioAction:
 *  Thank you, Apple, for deprecating the oh-so-easy-to-use NSMatrix.
 *  Now we have to manage our radio buttons manually instead of
 *  simply using bindings.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)radioAction:(id)sender
{
	self.currentTag = [sender tag];
	[self updateUserDefaultsForTag:self.currentTag];

	[self.view layoutSubtreeIfNeeded];
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
	 {
		 context.allowsImplicitAnimation = YES;

		 if ( [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyAnimationReduce] )
		 {
			 context.duration = 0.0f;
		 }
		 else
		 {
			 context.duration = [[NSUserDefaults standardUserDefaults] floatForKey:JSDKeyAnimationStandardTime];
		 }

		 [self updateLayoutForTag:[sender tag] view:self.serviceView];

	 } completionHandler:^() {
	 }];
}

/*———————————————————————————————————————————————————————————————————*
 * - otherAction:
 *  Although values are bound to user defaults, we need to update
 *  the composite default value whenever these other things are
 *  updated.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)otherAction:(id)sender
{
	[self updateUserDefaultsForTag:self.currentTag];
}


#pragma mark - Property Accessors


/*———————————————————————————————————————————————————————————————————*
 * @property sharedServer
 *   A shortcut for the shared built in server, but importantly, we
 *   can use as dependent keys and for binding.
 *———————————————————————————————————————————————————————————————————*/
- (JSDNuVServer *)sharedServer
{
	return [JSDNuVServer sharedNuVServer];
}

/*———————————————————————————————————————————————————————————————————*
 * @property defaults
 *   A shortcut for user defaults, but importantly, we can use
 *   user defaults as dependent keys.
 *———————————————————————————————————————————————————————————————————*/
- (NSUserDefaults *)defaults
{
	return [NSUserDefaults standardUserDefaults];
}

/*———————————————————————————————————————————————————————————————————*
 * @property urlBuiltIn
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingUrlBuiltIn
{
	NSArray *keyPaths = @[
						  [NSString stringWithFormat:@"defaults.%@", JSDKeyValidatorBuiltInPort],
						  [NSString stringWithFormat:@"defaults.%@", JSDKeyValidatorBuiltInUseLocalhost]
						  ];
	return [NSSet setWithArray:keyPaths];
}
- (NSString *)urlBuiltIn
{
	NSString *port = [[NSUserDefaults standardUserDefaults] stringForKey:JSDKeyValidatorBuiltInPort];

	if ( [[NSUserDefaults standardUserDefaults] boolForKey:JSDKeyValidatorBuiltInUseLocalhost] )
	{
		return [NSString stringWithFormat:@"http://localhost:%@", port];
	}

	enum { max_host = 255 };
	char host_name[max_host] = {0};
	gethostname(host_name, max_host);

	return [NSString stringWithFormat:@"http://%s:%@", host_name, port];
}


/*———————————————————————————————————————————————————————————————————*
 * @property urlW3C
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)urlW3C
{
	return @"https://validator.w3.org/nu";
}


/*———————————————————————————————————————————————————————————————————*
 * @property urlCustom
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingUrlCustom
{
	NSString *keyPath = [NSString stringWithFormat:@"defaults.%@", JSDKeyValidatorCustomServer];
	return [NSSet setWithArray:@[ keyPath ]];
}
- (NSString *)urlCustom
{
	return [self.defaults valueForKey:JSDKeyValidatorCustomServer];
}


/*———————————————————————————————————————————————————————————————————*
 * @property statusBuiltIn
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingStatusBuiltIn
{
	return [NSSet setWithArray:@[ @"sharedServer.serverStatus" ]];
}
- (NSImage *)statusBuiltIn
{
	switch ( self.sharedServer.serverStatus )
	{
		case JSDNuVServerPortUnavailable:
			self.statusBuiltInHint = JSDLocalizedString(@"nuv-hint-port-busy", nil);
			return [NSImage imageNamed:@"NSStatusUnavailable"];
			break;

		case JSDNuVServerStarting:
			self.statusBuiltInHint = JSDLocalizedString(@"nuv-hint-starting", nil);
			return [NSImage imageNamed:@"NSStatusPartiallyAvailable"];
			break;

		case JSDNuVServerRunning:
			self.statusBuiltInHint = JSDLocalizedString(@"nuv-hint-running", nil);
			return [NSImage imageNamed:@"NSStatusAvailable"];
			break;

		case JSDNuVServerStopped:
			self.statusBuiltInHint = JSDLocalizedString(@"nuv-hint-stopped", nil);
			return [NSImage imageNamed:@"NSStatusNone"];
			break;

		case JSDNuVServerExternalStop:
		default:
			self.statusBuiltInHint = JSDLocalizedString(@"nuv-hint-crashed", nil);
			return [NSImage imageNamed:@"NSStatusNone"];
			break;
	}
}


#pragma mark - Delegate Methods


/*———————————————————————————————————————————————————————————————————*
 * control:isValidObject:
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)control:(NSControl *)control isValidObject:(id)obj
{
	/* Ensure that we have a well-formed (or blank) URL for the custom server. */
	if ( control == self.fieldCustomServer )
	{
		NSString *string = obj;
		NSURL *url = [NSURL URLWithString:obj];
		return ( string.length == 0 ) || ( url && url.scheme && url.host );
	}

	return YES;
}


#pragma mark - Private Methods


/*———————————————————————————————————————————————————————————————————*
 * - updateLayoutForTag:view:
 *  Update all of the constraints and frames to reflect the hidden
 *  portions of the UI when a radio is not selected.
 *———————————————————————————————————————————————————————————————————*/
- (void)updateLayoutForTag:(NSInteger)tag view:(NSView *)topView
{
	double winAdjust = 0;

	for ( NSView *subview in topView.subviews)
	{
		if ( [subview isKindOfClass:[JSDCollapsingView class]] )
		{
			JSDCollapsingView *view = (JSDCollapsingView *)subview;

			BOOL willCollapse = view.panelNumber != tag;

			if ( willCollapse && !view.collapsed )
			{
				winAdjust = winAdjust - view.originalFrame.size.height;
			}

			if ( !willCollapse && view.collapsed )
			{
				winAdjust = winAdjust + view.originalFrame.size.height;
			}

			view.collapsed = willCollapse;
		}
	}

	NSRect windowFrame = self.serviceView.window.frame;
	windowFrame.size.height = windowFrame.size.height + winAdjust;
	windowFrame.origin.y = windowFrame.origin.y - winAdjust;

	/* We must animate the window frame, too, otherwise the window springs to its
	 new size before the animation takes effect, and everything jumps all over the
	 place. */
	[self.serviceView.window setFrame:windowFrame display:YES animate:YES];
	[self.view layoutSubtreeIfNeeded];
}


/*———————————————————————————————————————————————————————————————————*
 * - updateUserDefaultsForTag:
 *———————————————————————————————————————————————————————————————————*/
- (void)updateUserDefaultsForTag:(JSDValidatorSelectionType)tag
{
	[self.defaults setInteger:tag forKey:JSDKeyValidatorSelection];

	switch ( tag )
	{
		case JSDValidatorBuiltIn:
			[self.defaults setValue:[self.defaults valueForKey:JSDKeyValidatorAutoBuiltIn] forKey:JSDKeyValidatorAuto];
			[self.defaults setInteger:[self.defaults integerForKey:JSDKeyValidatorThrottleBuiltIn] forKey:JSDKeyValidatorThrottleTime];
			[self.defaults setValue:self.urlBuiltIn forKey:JSDKeyValidatorURL];
			break;

		case JSDValidatorW3C:
			[self.defaults setValue:[self.defaults valueForKey:JSDKeyValidatorAutoW3C] forKey:JSDKeyValidatorAuto];
			[self.defaults setInteger:[self.defaults integerForKey:JSDKeyValidatorThrottleW3C] forKey:JSDKeyValidatorThrottleTime];
			[self.defaults setValue:self.urlW3C forKey:JSDKeyValidatorURL];
			break;

		case JSDValidatorCustom:
		default:
			[self.defaults setValue:[self.defaults valueForKey:JSDKeyValidatorAutoCustom] forKey:JSDKeyValidatorAuto];
			[self.defaults setInteger:[self.defaults integerForKey:JSDKeyValidatorThrottleCustom] forKey:JSDKeyValidatorThrottleTime];
			[self.defaults setValue:self.urlCustom forKey:JSDKeyValidatorURL];
			break;
	}
}


#pragma mark - <MASPreferencesViewController> Support


- (BOOL)hasResizableHeight
{
	return NO;
}


- (BOOL)hasResizableWidth
{
	return NO;
}


- (NSString *)identifier
{
    return @"ValidatorOptionsPreferences";
}


- (NSImage *)toolbarItemImage
{
	return [[NSImage imageNamed:@"messages-validator"] tintedWithColor:[NSColor blueColor]];
}


- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"ValidatorPrefLabel", nil);
}

@end
