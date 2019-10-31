//
//  JSDNuValidator+SMLSyntaxError.m
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import "JSDNuValidator+MGSSyntaxError.h"


@implementation JSDNuValidator (MGSSyntaxError)


/*———————————————————————————————————————————————————————————————————*
 * @property fragariaErrorArray
 *———————————————————————————————————————————————————————————————————*/
- (NSArray<MGSSyntaxError *> *)fragariaErrorArray
{
    NSArray *localErrors = self.messages;
    NSMutableArray *highlightErrors = [[NSMutableArray alloc] init];
    
    for (NSDictionary *localError in localErrors)
    {
        MGSSyntaxError *newError = [MGSSyntaxError new];
        newError.errorDescription = localError[@"messageLocalized"];
        newError.line = [localError[@"firstLine"] intValue];
        newError.character = [localError[@"firstColumn"] intValue];
        newError.length = [localError[@"hiliteLength"] intValue];
        newError.hidden = NO;
        newError.warningImage = localError[@"typeImage"];
        [highlightErrors addObject:newError];
    }
    
    return highlightErrors;
}


@end
