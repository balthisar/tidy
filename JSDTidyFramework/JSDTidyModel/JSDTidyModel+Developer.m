/**************************************************************************************************
 
	JSDTidyModel
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.
 
 **************************************************************************************************/

#import "JSDTidyModel+Developer.h"
#import "JSDTidyOption.h"

@implementation JSDTidyModel (Developer)


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
 + optionsBuiltInDumpDocsToConsole (class)
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (void) optionsBuiltInDumpDocsToConsole
{
	NSArray* optionList = [[self class] optionsBuiltInOptionList];
	NSString* paddedOptionName;
	NSString* filteredDescription;
	NSAttributedString* convertingString;
	
	NSLog(@"%@", @"----START----");
	
	for (NSString* optionName in optionList)
	{
		paddedOptionName = [[NSString stringWithFormat:@"\"%@\"", optionName]
							stringByPaddingToLength:40
							withString:@" "
							startingAtIndex:0];
		
		filteredDescription = [[[[JSDTidyOption alloc] initWithName:optionName sharingModel:nil] builtInDescription]
							   stringByReplacingOccurrencesOfString:@"\""
							   withString:@"'"];
		
		filteredDescription = [filteredDescription
							   stringByReplacingOccurrencesOfString:@"<br />"
							   withString:@"\\n"];
		
		convertingString = [[NSAttributedString alloc]
							initWithHTML:[filteredDescription dataUsingEncoding:NSUnicodeStringEncoding]
							documentAttributes:nil];
		
		filteredDescription = [convertingString string];
		
		NSLog(@"%@= \"%@: %@\";", paddedOptionName, optionName, filteredDescription);
	}
	
	NSLog(@"%@", @"----STOP----");
	
}


@end
