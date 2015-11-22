/**************************************************************************************************

	FragariaBaseViewController
	 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "FragariaBaseViewController.h"


@implementation FragariaBaseViewController


#pragma mark - Embedded Controller Support

- (instancetype) initWithController:(NSViewController*)embeddedController
{
	if (self = [self init])
	{
		_embeddedController = embeddedController;
	}
	
	return self;
}


- (void) awakeFromNib
{
	self.embeddedView = self.embeddedController.view;
	
	[self.embeddedContainer addSubview:self.embeddedView];
	
	self.embeddedView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	
	[self.embeddedView setFrame:self.embeddedContainer.bounds];
}


#pragma mark - <MASPreferencesViewController> Support


- (id)init
{
    return [super initWithNibName:@"YouHaveToOverrideInit" bundle:nil];
}


- (BOOL)hasResizableHeight
{
	return NO;
}


- (BOOL)hasResizableWidth
{
	return NO;
}


- (NSString *)identifier
{
    return @"FragariaBaseViewController";
}


- (NSImage *)toolbarItemImage
{
	return nil;
}


- (NSString *)toolbarItemLabel
{
    return @"Label";
}

@end
