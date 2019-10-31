//
//  JSDTidyModel+SMLSyntaxError.m
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

#import "JSDTidyModel+MGSSyntaxError.h"


@implementation JSDTidyModel (MGSSyntaxError)


/*———————————————————————————————————————————————————————————————————*
 * @property fragariaErrorArray
 *———————————————————————————————————————————————————————————————————*/
- (NSArray<MGSSyntaxError *> *)fragariaErrorArray
{
    NSArray *localErrors = self.errorArray;
    NSMutableArray *highlightErrors = [[NSMutableArray alloc] init];
    
    for (NSDictionary *localError in localErrors)
    {
        MGSSyntaxError *newError = [MGSSyntaxError new];
        newError.errorDescription = localError[@"message"];
        newError.line = [localError[@"line"] intValue];
        newError.character = [localError[@"column"] intValue];
        newError.length = 1;
        newError.hidden = NO;
        newError.warningImage = localError[@"levelImage"];
        [highlightErrors addObject:newError];
    }
    
    return highlightErrors;
}


@end
