/**************************************************************************************************
 *
 *  JSDNuValidator+SMLSyntaxError
 *
 *  Copyright © 2018 by Jim Derry. All rights reserved.
 *
 **************************************************************************************************/

#import "JSDNuValidator+SMLSyntaxError.h"


@implementation JSDNuValidator (SMLSyntaxError)


/*———————————————————————————————————————————————————————————————————*
 * @property fragariaErrorArray
 *———————————————————————————————————————————————————————————————————*/
- (NSArray<SMLSyntaxError *> *)fragariaErrorArray
{
	NSArray *localErrors = self.messages;
	NSMutableArray *highlightErrors = [[NSMutableArray alloc] init];

	for (NSDictionary *localError in localErrors)
	{
		SMLSyntaxError *newError = [SMLSyntaxError new];
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
