/**************************************************************************************************
 
	AuxilliaryViewDelegate.h
 
	Copyright © 2003-2015 by Jim Derry. All rights reserved.
	
 **************************************************************************************************/

@import Foundation;


#pragma mark - protocol JSDTidyModelDelegate

/**
 *  The **AuxilliaryViewDelegate.h** protocol defines the interfaces for delegate methods used by
 *  auxilliary views and view-like controllers.
 */
@protocol AuxilliaryViewDelegate <NSObject>


@optional

/**
 *  Informs the delegate that the popup will close.
 */
- (void)auxilliaryViewWillClose:(id)sender;


@end

