/***************************************************************************************
    AppController.m -- part of Balthisar Tidy

    The main application controller, which ties together the PreferenceControllers and
    the BatchController. The DocumentController is implemented automatically, and no
    special works needs to be done.
 ***************************************************************************************/

#import <Cocoa/Cocoa.h>
#import "AppController.h"
#import "PreferenceController.h"
#import "BatchController.h"


@implementation AppController

/********************************************************************
    initialize
        when the class is created, we want to make sure all of the
        options are registered before anything else happens. We've\
        implemented this functionality as a class method in our
        PreferenceController class, which works quite nicely and
        we don't have to intermix that stuff directly in our code
        here.
*********************************************************************/
+(void)initialize {
    [PreferenceController registerUserDefaults];
} // end initialize

/********************************************************************
    dealloc
        make sure that the preference controller and batch controller
        are properly disposed of.
*********************************************************************/
- (void)dealloc {
    [preferenceController release];
    [batchController release];
    [super dealloc];
} // end dealloc

/********************************************************************
    showPreferences
        show the prefereces window.
*********************************************************************/
- (IBAction)showPreferences:(id)sender {
    // is preferenceController instance variable (outlet) nil?
    // if so, then we need to create it.
    if (!preferenceController) {
        preferenceController = [[PreferenceController alloc] init];
    }
    // ...and now show it
    [preferenceController showWindow:self];
} // end showPreferences


/********************************************************************
    showBatch
        show the batch window.
*********************************************************************/
- (IBAction)showBatch:(id)sender {
    // is batchController instance variable (outlet) nil?
    // if so, then we need to create it.
    if (!batchController) {
        batchController = [[BatchController alloc] init];
    }
    // ...and now show it
    [batchController showWindow:self];
} // end showBatch

@end
