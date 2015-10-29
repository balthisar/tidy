 /**************************************************************************************************
 
	TidyDocumentService
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.
 
 **************************************************************************************************/

#import "TidyDocumentService.h"
#import "CommonHeaders.h"

#import "JSDTidyModel.h"
#import "JSDTidyOption.h"
#import "TidyDocument.h"


@implementation TidyDocumentService


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  - newDocumentWithSelection:userData:error
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
- (void)newDocumentWithSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
#ifdef FEATURE_SUPPORTS_SERVICE
    /* Test for strings on the pasteboard. */
    NSArray *classes = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    if (![pboard canReadObjectForClasses:classes options:options])
	{
        *error = NSLocalizedString(@"tidyCantRead", nil);
        return;
    }
    
    /* Create a new document and set the text. */
    TidyDocument *localDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:nil];
    localDocument.sourceText = [pboard stringForType:NSPasteboardTypeString];
#endif
}


@end
