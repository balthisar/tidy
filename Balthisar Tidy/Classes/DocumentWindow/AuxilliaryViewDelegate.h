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
 *  **tidyModelOptionChange** will be called when one or more [JSDTidyModel tidyOptions] are changed.
 *
 *  The corresponding `NSNotification` is defined by `tidyNotifyOptionChanged`.
 *  @param tidyModel Indicates the instance of the **JSDTidyModel** that is calling the delegate.
 *  @param tidyOption Indicates which instance of **JSDTidyOption** was changed.
 */
- (void)auxilliaryViewWillClose:(id)sender;

@end

