/***************************************************************************************
    AppController.h -- part of Balthisar Tidy

    The main application controller, which ties together the PreferenceControllers and
    the BatchController. The DocumentController is implemented automatically, and no
    special works needs to be done.
 ***************************************************************************************/

#import <Foundation/Foundation.h>

@class PreferenceController;				// let compiler know that this exists!
@class BatchController;					// let compiler know that this exists!

@interface AppController : NSObject {
    PreferenceController *preferenceController;		// we need a PreferenceController instance for preferences.
    BatchController *batchController;			// we need a BatchController instance for the batch window.
}

- (IBAction)showPreferences:(id)sender;			// user wants to see the preferences.
- (IBAction)showBatch:(id)sender;			// user wants to see the batch window.


@end

