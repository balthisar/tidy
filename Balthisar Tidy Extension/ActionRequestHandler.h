//
//  ActionRequestHandler.h
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

@import Cocoa;

/**
 *  The Balthisar Tidy extension handles Action Extension requests in order to implement
 *  Action Extensions for Mac OS X 10.10+. This particular class handles "Tidy with 
 *  Balthisar Tidy" and "Tidy with Balthisar Tidy (body only)".
 *
 *  Apple pointed out that the extension endpoint com.apple.services is only
 *  for iOS, which means that we *must* use com.apple.ui-services. This means
 *  on Mac OS X we *have* to inherit from NSViewController. There's a dummy
 *  nib, too, to facilitate this.
 *
 *  This extension is implemented via multiple build targets to support each version
 *  of Balthisar Tidy, but also implemented separately via the BODY_ONLY preprocessor
 *  macros support the very minor functionality between the full and body-only version.
 */

@interface ActionRequestHandler : NSObject <NSExtensionRequestHandling>

/**
 *  Tidy's the provided text and returns it.
 */
- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context;

@end
