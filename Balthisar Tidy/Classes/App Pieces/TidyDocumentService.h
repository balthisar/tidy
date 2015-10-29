/**************************************************************************************************

	TidyDocumentService

	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

@import Cocoa;


/**
 *  This class provides the functions for allowing Balthisar Tidy proper to provides its
 *  System Services.
 */
@interface TidyDocumentService : NSObject

/**
 *  Handle the "New Balthisar Tidy Document with Selection" system service.
 *  @param userData Contains the dirty text selected by the user.
 *  @param error The pointer to potential error data returned if the method fails.
 */
- (void)newDocumentWithSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

@end
