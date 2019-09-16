//
//  MGSColourSchemeListController.h
//  Fragaria
//
//  Created by Jim Derry on 3/16/15.
//
/// @cond PRIVATE

#import <Cocoa/Cocoa.h>

@class MGSPreferencesController;
@class MGSPrefsColourPropertiesViewController;
@class MGSColourScheme;
@class MGSMutableColourScheme;


/** Class which stores information for one menu entry of MGSColourSchemeListController. */
@interface MGSColourSchemeOption : NSObject

/** The colour scheme */
@property (nonatomic) MGSMutableColourScheme *colourScheme;

/** Indicates if this definition was loaded from a bundle, and thus
 *  it should not be editable. */
@property (nonatomic, assign) BOOL loadedFromBundle;

/** Indicates the complete and path and filename this instance was loaded
 *  from (if any).
 *  @note If you are saving the schemes to a file, you can leverage the
 *    default implementation of -deleteColourScheme:error: in
 *    MGSColourSchemeListController if you set this property accordingly. */
@property (nonatomic, strong) NSURL *sourceURL;

@end


/**
 *  MGSColourSchemeListController manages a list of MGSColourSchemes,
 *  and provides bindings for use in UI applications to support basic editing
 *  operations. As an NSArrayController descendant, it can be instantiated by IB.
 *  All functions are performed by modifying the color scheme through a separate
 *  NSObjectController (set through the colourSchemeController property)
 *  which should manage the colour scheme displayed by the rest of the user
 *  interface.
 *
 *  By default, schemes are loaded first from the framework bundle, then the
 *  application bundle, then finally from the application's Application Support
 *  folder. Schemes are saved in the application's Application Support/Colour
 *  Schemes directory, and only those schemes can be deleted. You can customize
 *  this behavior by overriding the appropriate load and save methods.
 *
 *  To create a new scheme, the user modifies an already existing scheme through
 *  the colourSchemeController, at which point the name of the scheme changes to
 *  Custom Settings. This scheme can then be saved when ready.
 *
 *  This makes it impossible to modify existing schemes per se, however the
 *  workaround is to modify the existing scheme and save it with a new name,
 *  The previous version can then be selected and deleted. This is consistent
 *  with the behaviour of many other text editors.
 **/
@interface MGSColourSchemeListController : NSArrayController


/** A reference to the NSObjectController whose content is the instance of
 *  MGSColourScheme being edited. */
@property (nonatomic) IBOutlet NSObjectController *colourSchemeController;


#pragma mark - Behavior for Custom Schemes
/// @name Behavior for Custom Schemes

/** Set to YES if you don't want to support scheme editing.
 *  @discussion When set to YES; any modification to colourSchemeController which
 *     results in a scheme not already in the list, will cause the value
 *     of colourSchemeController to reset to the scheme returned by
 *     the defaultScheme property. */
@property (nonatomic) BOOL disableCustomSchemes;

/** The default colour scheme to use when disableCustomSchemes is YES and
 *  colourSchemeController is set to a scheme not in the list. */
@property (nonatomic, readonly) MGSColourScheme *defaultScheme;


#pragma mark - Support for a Save/Delete button
/// @name Support for a Save/Delete button

/** The current correct state of a save/delete button. Bind the button's
 *  enabled binding to this property in Interface Builder to ensure its correct
 *  state. */
@property (nonatomic, assign, readonly) BOOL buttonSaveDeleteEnabled;

/** A title for the save/delete button. Bind the button's title to this property
 *  in interface builder for automatic localized button name. */
@property (nonatomic, assign, readonly) NSString *buttonSaveDeleteTitle;

/** The add/delete button action.
 *  @note When your button's title is bound to buttonSaveDelete title,
 *  the title will update dynamically to reflect the correct action.
 *  @param sender The object that sent the action. */
- (IBAction)addDeleteButtonAction:(id)sender;


#pragma mark - Color Scheme Saving and Loading
/// @name Color Scheme Saving and Loading

/** Loads the initial list of color schemes.
 *  @note The default implementation creates the list from the built-in
 *    color schemes exported by MGSColourScheme, and from the options
 *    returned by -loadApplicationColourSchemes.
 *  @returns A list of colour scheme options. */
- (NSArray <MGSColourSchemeOption *> *)loadColourSchemes;

/** Loads the initial list of application-specific color schemes.
 *  @note The default implementation loads schemes from the "Colour Schemes"
 *    directory in the Resources directory of the application bundle, and
 *    from the "Colour Schemes" directory in the Application Support directory
 *    of the application.
 *  @returns A list of colour scheme options. */
- (NSArray <MGSColourSchemeOption *> *)loadApplicationColourSchemes;

/** Saves the color scheme in the specified option to persistent storage.
 *  @param scheme The option containing the colour scheme to save.
 *  @param err Set when an error occurs while saving.
 *  @return YES if saving has succeeded, otherwise NO. */
- (BOOL)saveColourScheme:(MGSColourSchemeOption *)scheme error:(NSError **)err;

/** Deletes from persistent storage the color scheme in the specified option.
 *  @param scheme The option containing the colour scheme to delete.
 *  @param err Set when an error occurs while deleting.
 *  @returns YES if the deletion has succeeded, otherwise NO. */
- (BOOL)deleteColourScheme:(MGSColourSchemeOption *)scheme error:(NSError **)err;


@end
