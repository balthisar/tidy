//
//  MGSColourSchemeTableViewController.h
//  FragariaDefaultsCoordinator
//
//  Created by Daniele Cattaneo on 02/07/2019.
//

#import <Cocoa/Cocoa.h>
#import <Fragaria/Fragaria.h>

NS_ASSUME_NONNULL_BEGIN

@class MGSMutableColourScheme;
@class MGSColourSchemeTableCellView;


/**
 *  A bindings-compatible controller-layer class for displaying and editing the contents of a
 *  MGSMutableColourScheme through a NSTableView.
 *
 *    To use this class, bind the currentScheme property to the color scheme to edit
 *  (or set it directly and use manual KVO on dictionaryRepresentation it to receive change
 *  notifications), set it as delegate and dataSource of a NSTableView, and connect the
 *  tableView outlet to the same NSTableView.
 */
@interface MGSColourSchemeTableViewDataSource : NSObject <NSTableViewDelegate, NSTableViewDataSource>


#pragma mark - Interface Builder Outlets
/// @name Interface Builder Outlets

/** The table view which will use this object as data source and delegate.
 *  @note When this property is set, the setup of the table view is changed
 *     automatically. */
@property (nonatomic) IBOutlet NSTableView *tableView;


#pragma mark - The Model Object
/// @name The Model Object

/** The scheme being edited.
 *  @note This property always reflects the state of the UI. When it is set
 *     to a MGSMutableColourScheme, it will mutate in-place. */
@property (nonatomic, strong) MGSColourScheme *currentScheme;


#pragma mark - Customizing the Table
/// @name Customizing the Table

/** Whether the table allows editing the options specific to each group. */
@property (nonatomic) BOOL showGroupProperties;

/** Whether the table allows editing the global properties of the scheme
 *  (like background color, text color, and so on). */
@property (nonatomic) BOOL showGroupGlobalProperties;

/** Whether the table shows section headers. */
@property (nonatomic) BOOL showHeaders;


/** Invoked when a table row is going to be updated.
 *  @param theView The table row view to update.
 *  @discussion This method is intended for custom subclasses to allow
 *    customizing in detail the appearance of each row. An overriding
 *    implementation must always invoke the base implementation.
 *  @warning Don't invoke -[MGSColourSchemeTableCellView updateView]
 *    from this method. */
- (void)updateView:(MGSColourSchemeTableCellView *)theView;

/** Invoked when a row is reset before it is used in the table.
 *  @param theView The table row view to update.
 *  @discussion This method is intended for custom subclasses to
 *    properly undo any modifications made to a table row before
 *    it is reused. An overriding implementation must always invoke
 *    the base implementation. */
- (void)prepareForReuseView:(MGSColourSchemeTableCellView *)theView;


/** The list of syntax groups that will be available for editing in the
 *  table view.
 *  @note By default this method returns the same list returned by
 *     -[MGSSyntaxController syntaxGroupsForParsers]. Since this list is
 *     cached to increase performance, ensure that all parsers you use
 *     are registered before this class is instantiated for the first time.
 *  @note You can selectively hide or show any syntax group by overriding
 *     this method.
 *  @note The names shown for each syntax group in the table are retrieved
 *     through -[MGSSyntaxController localizedDisplayNameForSyntaxGroup:].
 *  @warning This list of syntax groups must contain groups that the
 *     color scheme being edited can resolve. */
@property (nonatomic, readonly) NSArray<MGSSyntaxGroup> *colouringGroups;

/** The list of color properties of MGSColourScheme that are available
 *  for editing in the table view.
 *  @note You can selectively hide or show any global property by
 *     overriding this method.
 *  @warning All global properties returned by this method must be
 *     KVC-compliant. */
@property (nonatomic, readonly) NSArray<NSString *> *globalProperties;

/** Maps a global property name from the globalProperties property
 *  to a localized string suitable for display.
 *  @param prop The name of a property of MGSColourScheme.
 *  @returns A localized string describing the property in a
 *     human-readable way. */
- (NSString *)localizedStringForGlobalProperty:(NSString *)prop;

@end


#pragma mark - Accessing the Table Rows


/**
 * The table cell view used by MGSColourSchemeTableViewDataSource to display
 * non-separator content.
 */
@interface MGSColourSchemeTableCellView: NSView

#pragma mark - Interface Builder Outlets
/// @name Interface Builder Outlets

/** A button placed on the left side of the view. */
@property (nonatomic) IBOutlet NSButton *enabled;

/** A label used to display the property or group option name. */
@property (nonatomic) IBOutlet NSTextField *label;

/** A color well used to display and edit the color of the
 *  property or the group option. */
@property (nonatomic) IBOutlet NSColorWell *colorWell;

/** A segmented control with 3 segments corresponding to bold,
 *  italic and underline text font variants. */
@property (nonatomic) IBOutlet NSSegmentedControl *textVariant;


/** A reference to the MGSColourSchemeTableViewDataSource which
 *  created this view. */
@property (nonatomic, weak) MGSColourSchemeTableViewDataSource *parentVc;

/** The syntax group associated to this table row. nil if the row is
 *  used to edit a global property. */
@property (nonatomic, nullable) MGSSyntaxGroup syntaxGroup;

/** The global property name associated to this table row. nil if the
 *  row is used to edit the options for a syntax group. */
@property (nonatomic, nullable) NSString *globalPropertyKeyPath;


#pragma mark - Receiving and Sending Changes
/// @name Receiving and Sending Changes

/** An action received when the state of any UI element in the view
 *  changes.
 *  @param sender The object which sent the action. */
- (IBAction)updateScheme:(id)sender;

@end


NS_ASSUME_NONNULL_END
