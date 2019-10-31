//
//  AppController.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

@import Cocoa;
@import JSDNuVFramework;


/**
 *  This main application controller handles application startup, Preference, and target conditional
 *  differences such as Sparkle vs. non-sparkle.
 */
@interface AppController : NSObject <NSApplicationDelegate>


/**
 *  Show the Preferences window.
 */
- (IBAction)showPreferences:(id)sender;


/**
 *  Show the About window.
 */
- (IBAction)showAboutWindow:(id)sender;


/**
 *  Provide bindings access to the sharedDocumentController. It's best not to bind to its
 *  currentDocument items for anything other than global states because bindings are not
 *  changed when currentDocument changes.
 */
@property (nonatomic, assign, readonly) NSDocumentController *sharedDocumentController;


/**
 *  Provides bindings access to the sharedNuvServer.
 */
@property (nonatomic, assign, readonly) JSDNuVServer *sharedNuVServer;

@end

