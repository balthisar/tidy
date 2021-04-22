//
//  TDFTidyTableViewController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "TDFTidyTableViewController.h"
#import "CommonHeaders.h"

@import JSDTidyFramework;


@interface TDFTidyTableViewController ()

/* Reference to the view with the filter buttons, so that it can be shown/hidden. */
@property (nonatomic, assign) IBOutlet NSView *filterView;

/* Indicates/controls whether or not the filterView is hidden. */
@property (nonatomic, assign) BOOL filterViewIsHidden;

@end

@implementation TDFTidyTableViewController


#pragma mark - Initialization


/*———————————————————————————————————————————————————————————————————*
 * showsFilterInfo
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
    if ((self = [super init]))
    {
        self.showsMessages = TMSGInfo | TMSGWarnings | TMSGErrors | TMSGAccess | TMSGOther;
    }
    
    return self;
}


#pragma mark - Property Accessors


/*———————————————————————————————————————————————————————————————————*
 * Take care of key dependencies for property accessors.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    NSArray *showsMessagesDependents = @[
        @"labelForInfo",
        @"labelForWarnings",
        @"labelForErrors",
        @"labelForAccess",
        @"labelForOther",
    ];
    
    if ( [showsMessagesDependents containsObject:key])
    {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"self.representedObject.tidyProcess.errorArray"]];
    }
    
    return keyPaths;
}


/*———————————————————————————————————————————————————————————————————*
 * showsFilterInfo
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsFilterInfo
{
    return self.showsMessages & TMSGInfo;
}

- (void)setShowsFilterInfo:(BOOL)showsFilterInfo
{
    self.showsMessages = self.showsMessages ^ TMSGInfo;
    [self setCurrentPredicate];
}


/*———————————————————————————————————————————————————————————————————*
 * showsFilterWarnings
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsFilterWarnings
{
    return self.showsMessages & TMSGWarnings;
}

- (void)setShowsFilterWarnings:(BOOL)showsFilterWarnings
{
    self.showsMessages = self.showsMessages ^ TMSGWarnings;
    [self setCurrentPredicate];
}


/*———————————————————————————————————————————————————————————————————*
 * showsFilterErrors
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsFilterErrors
{
    return self.showsMessages & TMSGErrors;
}

- (void)setShowsFilterErrors:(BOOL)showsFilterErrors
{
    self.showsMessages = self.showsMessages ^ TMSGErrors;
    [self setCurrentPredicate];
}


/*———————————————————————————————————————————————————————————————————*
 * showsFilterAccess
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsFilterAccess
{
    return self.showsMessages & TMSGAccess;
}

- (void)setShowsFilterAccess:(BOOL)showsFilterAccess
{
    self.showsMessages = self.showsMessages ^ TMSGAccess;
    [self setCurrentPredicate];
}


/*———————————————————————————————————————————————————————————————————*
 * showsFilterOther
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)showsFilterOther
{
    return self.showsMessages & TMSGOther;
}

- (void)setShowsFilterOther:(BOOL)showsFilterOther
{
    self.showsMessages = self.showsMessages ^ TMSGOther;
    [self setCurrentPredicate];
}


/*———————————————————————————————————————————————————————————————————*
 * labelForInfo
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)labelForInfo
{
    NSUInteger messageCount = [self messageCountOfType:TidyInfo];
    
    NSString *labelString = JSDLocalizedString(@"filterInfo", nil);
    
    if (messageCount > 0)
    {
        labelString = [NSString stringWithFormat:@"%@ (%@)", labelString, @(messageCount)];
    }
    
    return labelString;
}


/*———————————————————————————————————————————————————————————————————*
 * labelForWarnings
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)labelForWarnings
{
    NSUInteger messageCount = [self messageCountOfType:TidyWarning];
    
    NSString *labelString = JSDLocalizedString(@"filterWarnings", nil);
    
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
    NSUInteger messageCount = [self messageCountOfType:TidyError];
    
    NSString *labelString = JSDLocalizedString(@"filterErrors", nil);
    
    if (messageCount > 0)
    {
        labelString = [NSString stringWithFormat:@"%@ (%@)", labelString, @(messageCount)];
    }
    
    return labelString;
}


/*———————————————————————————————————————————————————————————————————*
 * labelForAccess
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)labelForAccess
{
    NSUInteger messageCount = [self messageCountOfType:TidyAccess];
    
    NSString *labelString = JSDLocalizedString(@"filterAccess", nil);
    
    if (messageCount > 0)
    {
        labelString = [NSString stringWithFormat:@"%@ (%@)", labelString, @(messageCount)];
    }
    
    return labelString;
}


/*———————————————————————————————————————————————————————————————————*
 * labelForOther
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)labelForOther
{
    NSUInteger messageCount = [self messageCountOfType:TidyFatal];
    messageCount += [self messageCountOfType:TidyConfig];
    messageCount += [self messageCountOfType:TidyBadDocument];
    
    NSString *labelString = JSDLocalizedString(@"filterOther", nil);
    
    if (messageCount > 0)
    {
        labelString = [NSString stringWithFormat:@"%@ (%@)", labelString, @(messageCount)];
    }
    
    return labelString;
}


/*———————————————————————————————————————————————————————————————————*
 * hasMessageData
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingHasMessageData
{
    return [NSSet setWithArray:@[@"self.representedObject.tidyProcess.errorArray"]];
}
- (BOOL)hasMessageData
{
    uint count = [[self.arrayController valueForKeyPath:@"arrangedObjects.@count"] intValue];
    
    return count != 0;
}


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

#pragma mark - Instance Methods


/*———————————————————————————————————————————————————————————————————*
 * Counts the given items in the arrayController.
 *———————————————————————————————————————————————————————————————————*/
- (NSUInteger)messageCountOfType:(TidyReportLevel)reportLevel
{
    NSArray *errorArray = [self valueForKeyPath:@"self.arrayController.arrangedObjects"];
    
    NSIndexSet *indexSet = [errorArray indexesOfObjectsPassingTest:^BOOL(id message, NSUInteger idx, BOOL *stop) {
        return ((JSDTidyMessage *)message).level == reportLevel;
    }];
    
    return [indexSet count];
}


/*———————————————————————————————————————————————————————————————————*
 * Builds the current predicate given the current conditions.
 *———————————————————————————————————————————————————————————————————*/
- (void)setCurrentPredicate
{
    NSMutableArray *filterCurrent = [[NSMutableArray alloc] init];
    
    if ( self.showsMessages & TMSGInfo )
    {
        [filterCurrent addObject:[NSString stringWithFormat:@"level = %@", @(TidyInfo)]];
    }
    
    if ( self.showsMessages & TMSGWarnings )
    {
        [filterCurrent addObject:[NSString stringWithFormat:@"level = %@", @(TidyWarning)]];
    }
    
    if ( self.showsMessages & TMSGErrors )
    {
        [filterCurrent addObject:[NSString stringWithFormat:@"level = %@", @(TidyError)]];
    }
    
    if ( self.showsMessages & TMSGAccess )
    {
        [filterCurrent addObject:[NSString stringWithFormat:@"level = %@", @(TidyAccess)]];
    }
    
    if ( self.showsMessages & TMSGOther )
    {
        [filterCurrent addObject:[NSString stringWithFormat:@"level = %@ || level = %@ || level = %@", @(TidyConfig), @(TidyBadDocument), @(TidyFatal)]];
    }
    
    NSString *filterString = [filterCurrent componentsJoinedByString:@" OR "];
    
    if ([filterString isEqualToString:@""])
    {
        [self.arrayController setFilterPredicate:[NSPredicate predicateWithFormat:@"level = -1"]];
    }
    else
    {
        [self.arrayController setFilterPredicate:[NSPredicate predicateWithFormat:filterString]];
    }
}

@end
