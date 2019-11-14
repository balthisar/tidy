//
//  NSApplication+ServiceApplication.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import <objc/runtime.h>
#import "NSApplication+ServiceApplication.h"
#import "CommonHeaders.h"
#import "AppDelegate.h"

@import JSDTidyFramework;

static char sourceTextKey;

@implementation NSApplication (ServiceApplication)


#pragma mark - Properties useful to implementors


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @sourceText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)sourceText
{
    return objc_getAssociatedObject(self, &sourceTextKey);
}

- (void)setSourceText:(NSString *)sourceText
{
    objc_setAssociatedObject(self, &sourceTextKey, sourceText, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @tidyText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)tidyText
{
    return [self performTidy:self.sourceText bodyOnly:NO];
}


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * @tidyBodyText
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)tidyBodyText
{
    return [self performTidy:self.sourceText bodyOnly:YES];
}


#pragma mark - Private


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 * - performTidy:bodyOnly:
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (NSString *)performTidy:(NSString *)sourceText bodyOnly:(BOOL)bodyOnly
{
    JSDTidyModel *localModel = [[JSDTidyModel alloc] initWithString:sourceText];
    NSUserDefaults *localDefaults = [(AppDelegate*)[self delegate] sharedUserDefaults];

    [localModel takeOptionValuesFromDefaults:localDefaults];
    JSDTidyOption *localOption = localModel.tidyOptions[@"force-output"];
    localOption.optionValue = @"YES";
    
    localOption = localModel.tidyOptions[@"show-body-only"];
    localOption.optionValue = bodyOnly ? @"1" : @"0";
    
    localModel.sourceText = sourceText;
    
    return localModel.tidyText;
}


@end
