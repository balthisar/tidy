/**************************************************************************************************

	TDFTableViewController

	Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "TDFValidatorViewController.h"
#import "CommonHeaders.h"

#import "TidyDocument.h"

@import JSDTidyFramework;
@import JSDNuVFramework;

@interface TDFValidatorViewController ()

/* Convenience accessors. */
@property (nonatomic, assign, readonly) JSDTidyModel *tidyProcess;
@property (nonatomic, assign, readonly) NSUserDefaults *defaults;
@property (nonatomic, assign, readonly) JSDNuVServer *sharedServer;

/* Redefine for category use. */
@property (nonatomic, readwrite, assign) BOOL inProgress;
@property (nonatomic, readwrite, assign) NSImage *imageForNetwork;

/* Internal Properties */
@property (nonatomic, readwrite, assign) BOOL sourceIsXML;
@property (nonatomic, readwrite, assign) BOOL tidyIsXML;
@property (nonatomic, readonly, assign) BOOL isReachable;



@end


@implementation TDFValidatorViewController

@synthesize modeIsTidyText = _modeIsTidyText;


#pragma mark - Initialization


/*———————————————————————————————————————————————————————————————————*
 * init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
    if ((self = [super init]))
    {
		self.showsMessages = JSDNuVInfo | JSDNuVError | JSDNuVNonDoc;
    }

    return self;
}


/*———————————————————————————————————————————————————————————————————*
 * Cleanup.
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
	[self.sourceValidator unbind:@"data"];
	[self.sourceValidator unbind:@"sourceIsXML"];
	[self.sourceValidator unbind:@"urlString"];
	[self.sourceValidator unbind:@"throttleTime"];
	[self.sourceValidator unbind:@"autoUpdate"];

	[self.tidyValidator unbind:@"data"];
	[self.tidyValidator unbind:@"tidyIsXML"];
	[self.tidyValidator unbind:@"urlString"];
	[self.tidyValidator unbind:@"throttleTime"];
	[self.tidyValidator unbind:@"autoUpdate"];

	[self.sharedServer removeObserver:self forKeyPath:@"serverStatus"];
}


/*———————————————————————————————————————————————————————————————————*
 * Create the validators.
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
	/******************************************************
	 * Validator setup.
	 ******************************************************/

	self.sourceValidator = [[JSDNuValidator alloc] init];
	self.tidyValidator = [[JSDNuValidator alloc] init];

	self.sourceValidator.delegate = self;
	self.tidyValidator.delegate = self;

	NSString *name = [NSBundle mainBundle].localizedInfoDictionary[@"CFBundleDisplayName"];
	NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
	NSString *userAgent = [NSString stringWithFormat:@"%@/%@ ( https://www.balthisar.com/software/tidy )", name, version];

	self.tidyValidator.userAgent = userAgent;
	self.sourceValidator.userAgent = userAgent;

	/* Bind the sourceText and tidyText to the validators directly. */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[self.sourceValidator bind:@"data"         toObject:self.tidyProcess withKeyPath:@"sourceTextAsData"         options:nil ];
	[self.sourceValidator bind:@"dataIsXML"    toObject:self             withKeyPath:@"sourceIsXML"              options:nil];
	[self.sourceValidator bind:@"throttleTime" toObject:defaults         withKeyPath:JSDKeyValidatorThrottleTime options:nil];
	[self.sourceValidator bind:@"autoUpdate"   toObject:defaults         withKeyPath:JSDKeyValidatorAuto         options:nil];
	[self.sourceValidator bind:@"urlString"    toObject:defaults         withKeyPath:JSDKeyValidatorURL          options:nil];

	[self.tidyValidator bind:@"data"         toObject:self.tidyProcess withKeyPath:@"tidyTextAsData"           options:nil ];
	[self.tidyValidator bind:@"dataIsXML"    toObject:self             withKeyPath:@"tidyIsXML"                options:nil];
	[self.tidyValidator bind:@"throttleTime" toObject:defaults         withKeyPath:JSDKeyValidatorThrottleTime options:nil];
	[self.tidyValidator bind:@"autoUpdate"   toObject:defaults         withKeyPath:JSDKeyValidatorAuto         options:nil];
	[self.tidyValidator bind:@"urlString"    toObject:defaults         withKeyPath:JSDKeyValidatorURL          options:nil];

	/******************************************************
	 * KVO on the built-in server status.
	 ******************************************************/

	[self.sharedServer addObserver:self forKeyPath:@"serverStatus" options:NSKeyValueObservingOptionNew context:nil];

	/******************************************************
	 * Remaining setup.
	 ******************************************************/

	self.showsMessages = JSDNuVInfo | JSDNuVError | JSDNuVNonDoc;
	self.modeIsTidyText = YES;
	self.inProgress = NO;
}


#pragma mark - Dependent Key Management


/*———————————————————————————————————————————————————————————————————*
 * Take care of key dependencies for property accessors.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {

	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	NSArray *showsMessagesDependents = @[
										 @"labelForInfo",
										 @"labelForErrors",
										 @"labelForNonDocErrors",
										 ];

	if ( [showsMessagesDependents containsObject:key])
	{
		keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"self.tidyValidator.messages", @"self.sourceValidator.messages"]];
	}

	return keyPaths;
}


#pragma mark - Property Accessors


/*———————————————————————————————————————————————————————————————————*
 * modeIsTidyText
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)modeIsTidyText
{
	return _modeIsTidyText;
}
- (void)setModeIsTidyText:(BOOL)modeIsTidyText
{
	_modeIsTidyText = modeIsTidyText;

	id object = modeIsTidyText ? self.tidyValidator : self.sourceValidator;
	[self.arrayController unbind:@"contentArray"];
	[self.arrayController bind:@"contentArray" toObject:object withKeyPath:@"messages" options:nil];

	/* Need to let everyone know which view receives jumps. */
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyTidyErrorsChanged object:self];
}


#pragma mark - Filter Property Accessors


/*———————————————————————————————————————————————————————————————————*
 * filterViewIsHidden
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)filterViewIsHidden
{
	return self.filterView.hidden;
}

- (void)setFilterViewIsHidden:(BOOL)filterViewIsHidden
{
	self.filterView.hidden = filterViewIsHidden;

	if (filterViewIsHidden)
	{
		[self.arrayController setFilterPredicate:nil];
	}
	else
	{
		[self setCurrentPredicate];
	}
}


/*———————————————————————————————————————————————————————————————————*
 * showsFilterInfo
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsFilterInfo
{
    return self.showsMessages & JSDNuVInfo;
}

- (void)setShowsFilterInfo:(BOOL)showsFilterInfo
{
    self.showsMessages = self.showsMessages ^ JSDNuVInfo;
    [self setCurrentPredicate];
}


/*———————————————————————————————————————————————————————————————————*
 * showsFilterErrors
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsFilterErrors
{
    return self.showsMessages & JSDNuVError;
}

- (void)setShowsFilterErrors:(BOOL)showsFilterErrors
{
    self.showsMessages = self.showsMessages ^ JSDNuVError;
    [self setCurrentPredicate];
}


/*———————————————————————————————————————————————————————————————————*
 * showsFilterNonDocErrors
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsFilterNonDocErrors
{
    return self.showsMessages & JSDNuVNonDoc;
}

- (void)setShowsFilterNonDocErrors:(BOOL)showsFilterNonDocErrors
{
    self.showsMessages = self.showsMessages ^ JSDNuVNonDoc;
    [self setCurrentPredicate];
}


/*———————————————————————————————————————————————————————————————————*
 * labelForInfo
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)labelForInfo
{
    NSUInteger messageCount = [self messageCountOfType:JSDNuVInfo];

    NSString *labelString = JSDLocalizedString(@"filterInfo", nil);

    if (messageCount > 0)
    {
        labelString = [NSString stringWithFormat:@"%@ (%@)", labelString, @(messageCount)];
    }

    return labelString;
}


/*———————————————————————————————————————————————————————————————————*
 * labelForErrors
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)labelForErrors
{
    NSUInteger messageCount = [self messageCountOfType:JSDNuVError];

    NSString *labelString = JSDLocalizedString(@"filterErrors", nil);

    if (messageCount > 0)
    {
        labelString = [NSString stringWithFormat:@"%@ (%@)", labelString, @(messageCount)];
    }

    return labelString;
}


/*———————————————————————————————————————————————————————————————————*
 * labelForNonDocErrors
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)labelForNonDocErrors
{
    NSUInteger messageCount = [self messageCountOfType:JSDNuVNonDoc];

    NSString *labelString = JSDLocalizedString(@"filterNonDocErrors", nil);

    if (messageCount > 0)
    {
        labelString = [NSString stringWithFormat:@"%@ (%@)", labelString, @(messageCount)];
    }

    return labelString;
}


#pragma mark - Network Icon Property Accessors


/*———————————————————————————————————————————————————————————————————*
 * tooltipForNetwork
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingTooltipForNetwork
{
	return [NSSet setWithArray:@[@"modeIsTidyText", @"isReachable", @"self.sourceValidator.errorText", @"self.tidyValidator.errorText"]];
}
- (NSString *)tooltipForNetwork
{
	if ( self.isReachable ) /* implies JSDNuVServerRunning, if true, and internal */
	{
		self.imageForNetwork = [NSImage imageNamed:@"NSStatusAvailable"];
		return JSDLocalizedString(@"validatorReachable", nil);
	}
	else if ( [self.defaults integerForKey:@"ValidatorSelection"] == JSDValidatorBuiltIn )
	{
		switch ( self.sharedServer.serverStatus )
		{
			case JSDNuVServerPortUnavailable:
				self.imageForNetwork = [NSImage imageNamed:@"NSStatusUnavailable"];
				return JSDLocalizedString(@"nuv-hint-port-busy", nil);
				break;

			case JSDNuVServerStarting:
				self.imageForNetwork = [NSImage imageNamed:@"NSStatusPartiallyAvailable"];
				return JSDLocalizedString(@"nuv-hint-starting", nil);
				break;

			case JSDNuVServerRunning:
				self.imageForNetwork = [NSImage imageNamed:@"NSStatusAvailable"];
				return JSDLocalizedString(@"nuv-hint-running", nil);
				break;

			case JSDNuVServerStopped:
				self.imageForNetwork = [NSImage imageNamed:@"NSStatusNone"];
				return JSDLocalizedString(@"nuv-hint-stopped", nil);
				break;

			case JSDNuVServerExternalStop:
			default:
				self.imageForNetwork = [NSImage imageNamed:@"NSStatusNone"];
				return JSDLocalizedString(@"nuv-hint-crashed", nil);
				break;
		}
	}
	else
	{
		self.imageForNetwork = [NSImage imageNamed:@"NSStatusUnavailable"];
		if ( self.modeIsTidyText )
		{
			return [self.tidyValidator validatorConnectionErrorText];
		}
		else
		{
			return [self.sourceValidator validatorConnectionErrorText];
		}
	}
}


#pragma mark - Other UI Property Accessors


/*———————————————————————————————————————————————————————————————————*
 * Provides a bindable source for status label text.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingStatusLabelText
{
	return [NSSet setWithArray:@[@"modeIsTidyText"]];
}
- (NSString *)statusLabelText
{
	return self.modeIsTidyText ? JSDLocalizedString(@"tidyTextLabel", nil) : JSDLocalizedString(@"sourceTextLabel", nil);
}


/*———————————————————————————————————————————————————————————————————*
 * Provides a bindable source for no-issues text.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingHasMessageData
{
	return [NSSet setWithArray:@[@"self.inProgress", @"self.modeIsTidyText"]];
}
- (BOOL)hasMessageData
{
	uint count = [[self.arrayController valueForKeyPath:@"arrangedObjects.@count"] intValue];

	return count != 0;
}


/*———————————————————————————————————————————————————————————————————*
 * Indicates whether or not any of the validators are in progress.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingInProgress
{
	return [NSSet setWithArray:@[@"self.sourceValidator.inProgress", @"self.tidyValidator.inProgress"]];
}
- (BOOL)inProgress
{
	return self.sourceValidator.inProgress || self.tidyValidator.inProgress;
}


#pragma mark - Property Accessors (Category)


/*———————————————————————————————————————————————————————————————————*
 * Indicates whether or not the validator's URL is reachable. This
 * means that we have no errors from the validator, and if using the
 * internal validator, it is in running state.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingIsReachable
{
	return [NSSet setWithArray:@[@"self.tidyValidator.validatorConnectionError",
								 @"defaults.ValidatorSelection",
								 @"sharedServer.serverStatus"
								 ]];
}
- (BOOL)isReachable
{
	if ( [self.defaults integerForKey:@"ValidatorSelection"] == JSDValidatorBuiltIn )
	{
		return ([JSDNuVServer sharedNuVServer].serverStatus == JSDNuVServerRunning) && !self.tidyValidator.validatorConnectionError;
	}

	return !self.tidyValidator.validatorConnectionError;
}


/*———————————————————————————————————————————————————————————————————*
 * A convenience accessor for the represented object's tidyProcess.
 *———————————————————————————————————————————————————————————————————*/
- (JSDTidyModel *)tidyProcess
{
    return ((TidyDocument*)self.representedObject).tidyProcess;
}


/*———————————————————————————————————————————————————————————————————*
 * A convenience accessor for user defaults.
 *———————————————————————————————————————————————————————————————————*/
- (NSUserDefaults *)defaults
{
	return [NSUserDefaults standardUserDefaults];
}


/*———————————————————————————————————————————————————————————————————*
 * A convenience accessor for the shared server.
 *———————————————————————————————————————————————————————————————————*/
- (JSDNuVServer *)sharedServer
{
	return [JSDNuVServer sharedNuVServer];
}


/*———————————————————————————————————————————————————————————————————*
 * Determines whether or not the data are XML.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingSourceIsXML
{
	return [NSSet setWithArray:@[@"self.tidyProcess.tidyOptions.input-xml"] ];
}

- (BOOL)sourceIsXML
{
	JSDTidyOption *xmlOpt = [self.tidyProcess.tidyOptions objectForKey:@"input-xml"];

	/* Fucking Cocoa casting my string to NSCFNumber. */
	if ( [xmlOpt.optionUIValue isKindOfClass:[NSNumber class]] )
	{
		return [xmlOpt.optionUIValue integerValue] == 1;
	}
	else
	{
		return [xmlOpt.optionUIValue isEqualToString:@"1"];
	}
}


/*———————————————————————————————————————————————————————————————————*
 * Determines whether or not the data are XML.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingTidyIsXML
{
	return [NSSet setWithArray:@[@"self.tidyProcess.tidyOptions.output-xml"] ];
}

- (BOOL)tidyIsXML
{
	JSDTidyOption *xmlOpt = [self.tidyProcess.tidyOptions objectForKey:@"output-xml"];

	/* Fucking Cocoa casting my string to NSCFNumber. */
	if ( [xmlOpt.optionUIValue isKindOfClass:[NSNumber class]] )
	{
		return [xmlOpt.optionUIValue integerValue] == 1;
	}
	else
	{
		return [xmlOpt.optionUIValue isEqualToString:@"1"];
	}
}


#pragma mark - Action Methods


/*———————————————————————————————————————————————————————————————————*
 * Refresh both of the validators, now.
 *———————————————————————————————————————————————————————————————————*/
- (IBAction)handleRefresh:(id)sender
{
	[self.sourceValidator performValidation];
	[self.tidyValidator performValidation];
}


#pragma mark - Instance Methods


/*———————————————————————————————————————————————————————————————————*
 * Counts the given items in the arrayController.
 *———————————————————————————————————————————————————————————————————*/
- (NSUInteger)messageCountOfType:(JSDNuVMessageTypes)type
{
    NSArray *errorArray = [self valueForKeyPath:@"self.arrayController.arrangedObjects"];

    NSIndexSet *indexSet = [errorArray indexesOfObjectsPassingTest:^BOOL(id message, NSUInteger idx, BOOL *stop) {
		return ((JSDNuVMessage *)message).typeID == type;
    }];

    return [indexSet count];
}


/*———————————————————————————————————————————————————————————————————*
 * Builds the current predicate given the current conditions.
 *———————————————————————————————————————————————————————————————————*/
- (void)setCurrentPredicate
{
    NSMutableArray *filterCurrent = [[NSMutableArray alloc] init];

    if ( self.showsMessages & JSDNuVInfo )
    {
		[filterCurrent addObject:[NSString stringWithFormat:@"typeID = %@", @(JSDNuVInfo)]];
    }

    if ( self.showsMessages & JSDNuVError )
    {
		[filterCurrent addObject:[NSString stringWithFormat:@"typeID = %@", @(JSDNuVError)]];
    }

    if ( self.showsMessages & JSDNuVNonDoc )
    {
		[filterCurrent addObject:[NSString stringWithFormat:@"typeID = %@", @(JSDNuVNonDoc)]];
    }

    NSString *filterString = [filterCurrent componentsJoinedByString:@" OR "];

    if ([filterString isEqualToString:@""])
    {
        [self.arrayController setFilterPredicate:[NSPredicate predicateWithFormat:@"type = -1"]];
    }
    else
    {
        [self.arrayController setFilterPredicate:[NSPredicate predicateWithFormat:filterString]];
    }
}


#pragma mark - Delegate Methods

/*———————————————————————————————————————————————————————————————————*
 * When validation is complete, we need to inform everyone that the
 * error views might need to be updated.
 *———————————————————————————————————————————————————————————————————*/
- (void)validationComplete:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:tidyNotifyTidyErrorsChanged object:self];
}


#pragma mark - KVO


/*———————————————————————————————————————————————————————————————————*
 * If we're using the internal server, then it takes a bit of time
 * for it to come online when first launching. Let's validate the
 * document as soon as it's available.
 *———————————————————————————————————————————————————————————————————*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if ( [keyPath isEqualToString:@"serverStatus"] && [[NSUserDefaults standardUserDefaults] integerForKey:@"ValidatorSelection"] == JSDValidatorBuiltIn )
	{
		if ( self.sharedServer.serverStatus == JSDNuVServerRunning )
		{
			[self handleRefresh:nil];
		}
	}
}




@end
