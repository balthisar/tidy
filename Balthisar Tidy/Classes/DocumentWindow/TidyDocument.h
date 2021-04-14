//
//  TidyDocument.h
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

@import Cocoa;

@class JSDTidyModel;
@class TidyDocumentWindowController;


/**
 *  The main document controller, **TidyDocument** manages a single Tidy
 *  document and mediates access between the TidyDocumentWindowController
 *  and the JSDTidyModel processor.
 */
@interface TidyDocument : NSDocument


#pragma mark - General document control properties

/**
 *  Instance of JSDTidyModel that will perform all Tidying work.
 */
@property (nonatomic, strong, readonly) JSDTidyModel *tidyProcess;

/**
 *  The original, loaded data if opened from file.
 */
@property (nonatomic, strong, readonly) NSData *documentOpenedData;

/**
 *  Flag to indicate that the document is in loading process.
 */
@property (nonatomic, assign) BOOL documentIsLoading;

/**
 *  The associated windowcontroller.
 */
@property (nonatomic, strong) TidyDocumentWindowController *windowController;


#pragma mark - Properties used for AppleScript support


/**
 *  Exposes the text value of the sourceText view, and is mostly for AppleScript KVC support.
 */
@property (nonatomic, assign) NSString *sourceText;

/**
 *  Exposes the text value of the tidyText view, and is mostly for AppleScript KVC support.
 */
@property (nonatomic, assign, readonly) NSString *tidyText;


@end
