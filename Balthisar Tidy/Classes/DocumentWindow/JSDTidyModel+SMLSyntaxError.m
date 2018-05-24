/**************************************************************************************************
 *
 *  JSDTidyModel+SMLSyntaxError
 *
 *  Copyright © 2018 by Jim Derry. All rights reserved.
 *
 **************************************************************************************************/

#import "JSDTidyModel+SMLSyntaxError.h"


@implementation JSDTidyModel (SMLSyntaxError)


/*———————————————————————————————————————————————————————————————————*
 * @property fragariaErrorArray
 *———————————————————————————————————————————————————————————————————*/
- (NSArray<SMLSyntaxError *> *)fragariaErrorArray
{
	NSArray *localErrors = self.errorArray;
	NSMutableArray *highlightErrors = [[NSMutableArray alloc] init];

	for (NSDictionary *localError in localErrors)
	{
		SMLSyntaxError *newError = [SMLSyntaxError new];
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
