/**************************************************************************************************
 *
 *  JSDNuValidatorDelegate
 *
 *  Copyright © 2003-2018 by Jim Derry. All rights reserved.
 *
 **************************************************************************************************/

@import Foundation;


#pragma mark - protocol JSDNuValidatorDelegate

/**
 *  The **AuxilliaryViewDelegate.h** protocol defines the interfaces for delegate methods used by
 *  auxilliary views and view-like controllers.
 */
@protocol JSDNuValidatorDelegate <NSObject>


@optional

/**
 *  Informs the delegate validation has completed.
 */
- (void)validationComplete:(id)sender;


@end

