//
//  JSDTidyOption.h
//  JSSDTidyFramework
//
//  Copyright © 2003-2019 by Jim Derry. All rights reserved.
//

@import Cocoa;

@import HTMLTidy;

@class JSDTidyModel;


/**
 *  @c JSDTidyOption encapsulates a lot of GUI-oriented functionality around
 *  @b libtidy options.
 *
 *  Instances of @c JSDTidyOption belong to a @c sharedTidyModel but are
 *  largely self aware and handle most aspects of their operation on their own.
 *  They also provide good exposure to implementing user interfaces.
 *
 *  The principle purpose is to hold and store options, and return information
 *  about options. There is some interactivity among options (e.g., where we
 *  override character encodings), but this is always mediated back through to
 *  the @c sharedTidyModel. Setting an instance of an option does not cause
 *  tidying per se; this is all managed by the @c JSDTidyModel, which receives
 *  notifications that an item has changed.
 */
@interface JSDTidyOption : NSObject


#pragma mark - Initializers


/**
 *  Initializes an instance of @c JSDTidyOption, assigning it to an owning
 *  instance of @c JSDTidyModel.
 *
 *  @param sharedTidyModel The @c JSDTidyModel that this option instance
 *    belongs to.
 */
- (instancetype)initSharingModel:(JSDTidyModel *)sharedTidyModel;

/**
 *  Initializes an instance of @c JSDTidyOption, assigning it to an owning
 *  instance of @c JSDTidyModel, and assigning the option name.
 *
 *  @param name The name of the Tidy option that this instance represents,
 *    e.g., @b wrap.
 *  @param sharedTidyModel The @c JSDTidyModel that this option instance
 *    belongs to.
 */
- (instancetype)initWithName:(NSString *)name
                sharingModel:(JSDTidyModel *)sharedTidyModel;

/**
 *  Initializes an instance of @c JSDTidyOption, assigning it to an owning
 *  instance of @c JSDTidyModel, and assigning the option name and initial
 *  value.
 *
 *  @param name The name of the Tidy option that this instance represents,
 *    e.g., @b wrap.
 *  @param value The Tidy option value to set.
 *  @param sharedTidyModel The @c JSDTidyModel that this option instance
 *    belongs to.
 */
- (instancetype)initWithName:(NSString *)name
                 optionValue:(NSString *)value
                sharingModel:(JSDTidyModel *)sharedTidyModel;


#pragma mark - Main Properties


/**
 *  Returns the @b libtidy built-in option name.
 */
@property (nonatomic, strong, readonly) NSString *name;

/**
 *  The current value of this option. See also @c optionUIValue.
 *
 *  Note that this property is an @c NSString regardless of the data type in
 *  @b libtidy, and because @c JSDTidyFramework takes over character encoding
 *  from @b libtidy, encoding-related Tidy options must be specified as an
 *  @c NSStringEncoding (the @c NSString representation thereof, e.g. @@"12345").
 */
@property (nonatomic, strong) NSString *optionValue;

/**
 *  Default value of this option. This value will be read from
 *  @c NSUserDefaults. Compare with @c builtInDefaultValue, and see also
 *  @c JSDKeyTidyTidyOptionsKey in @b JSDTidyCommonHeaders.h.
 */
@property (nonatomic, assign, readonly) NSString *defaultOptionValue;

/**
 *  Array of string values for possible option values, for options that have
 *  pick-lists. Items without pick-lists will return an array with zero
 *  elements.
 */
@property (nonatomic, assign, readonly) NSArray *possibleOptionValues;

/**
 *  Indicates whether or not option is read-only.
 */
@property (nonatomic, assign, readonly) BOOL optionIsReadOnly;

/**
 *  Localized, humanized name of the option.
 *  Localized strings come from @b Localizable.strings.
 */
@property (nonatomic, strong, readonly) NSString *localizedHumanReadableName;

/**
 *  Localized description of the option in RTF format.
 *  Localized strings come from @b Localizable.strings.
 */
@property (nonatomic, strong, readonly) NSAttributedString *localizedHumanReadableDescription;

/**
 *  Localized name of the option category.
 *  Localized strings come from @b Localizable.strings.
 */
@property (nonatomic, strong, readonly) NSString *localizedHumanReadableCategory;


#pragma mark - Properties Useful for Implementing User Interfaces


/**
 *  Provides option values suitable for use in user-interfaces. See also
 *  @c optionValue.
 *
 *  The standard @c optionValue uses a human readable string to represent the
 *  option, regardless of datatype. When implementing UI applications it can be
 *  convenient to get or set the value in a more convenient format, and so this
 *  alternate property allows such. Specifically:
 *
 *  @li - NSStringEncoding is converted back and forth to index positions
 *        within @c [JSDStringEncodingTools @c encodingNames], making menu
 *        implementations simpler.
 *  @li - @c doctype option is transformed back and forth to menu index
 *        positions.
 *
 *  (A modern implementation might use Data Transformers instead of providing
 *  alternate accessors, but these haven't been implemented.)
 */
@property (nonatomic, assign) NSString *optionUIValue;

/**
 *  Suggests an object class to use for setting Tidy options. This is returned
 *  as a string to make bindings very easy, and can be converted back to a
 *  class (if needed) in code.
 *
 * @b libtidy option types can be @c TidyString, @c TidyInteger, or
 * @c TidyBoolean. Consequently @c JSDTidyOption will return one of three
 * classes suitable for using in a UI:
 *
 * @li  - @c NSPopupButton if the type has a non-empty pick list.
 * @li  - @c NSStepper, if the type is TidyInteger.
 * @li  - @c NSTextField, if none of the two work.
 */
@property (nonatomic, assign, readonly) NSString *optionUIType;

/**
 *  String representation of a tidy option with value suitable for use in a
 *  Tidy options configuration document.
 *
 *  Note that currently any encoding options are set to utf8 as the value.
 */
@property (nonatomic, assign, readonly) NSString *optionConfigString;

/**
 *  The NSUserDefaults instance to get defaults from.
 */
@property (nonatomic, strong) NSUserDefaults *userDefaults;


#pragma mark - Properties Maintained for Original libtidy compatability (may be used internally)


/**
 *  Tidy's internal @c TidyOptionId for this option.
 */
@property (nonatomic, assign, readonly) TidyOptionId optionId;

/**
 *  Actual type that @b libtidy expects.
 */
@property (nonatomic, assign, readonly) TidyOptionType optionType;

/**
 *  @b libtidy's built-in default value for this option.
 */
@property (nonatomic, assign, readonly) NSString *builtInDefaultValue;

/**
 *  @b libtidy's built-in description for this option. The text may be
 *  different than that returned by localizedHumanReadableDescription,
 *  as @b Localized.strings requires manual syncronization with
 *  @b libtidy releases, and @c builtInDescription is provided
 *  directly by @b libtidy.
 */
@property (nonatomic, assign, readonly) NSString *builtInDescription;

/**
 *  @b libtidy's built-in category for this option.
 */
@property (nonatomic, assign, readonly) TidyConfigCategory builtInCategory;


#pragma mark - Properties Used Mostly Internally or for Implementing User Interfaces


/**
 *  @c JSDTidyModel instance to which this option belongs.
 */
@property (nonatomic, assign, readonly) JSDTidyModel *sharedTidyModel;

/**
 *  Indicates whether or not this option is an encoding option.
 *
 *  @c JSDTidyFramework takes control of all encoding options from @b libtidy
 *  because Mac OS X offers many more encoding options.
 */
@property (nonatomic, assign, readonly) BOOL optionIsEncodingOption;

/**
 *  Fake option is only a header row for UI use.
 *
 *  The implementing application may want to include header rows mixed in with
 *  the options array. This flag indicates that an options instance isn't a
 *  real option at all, and can be used to flag header behavior if desired.
 *
 *  If using bindings, make sure you exclude options with this flag set.
 */
@property (nonatomic, assign) BOOL optionIsHeader;

/**
 *  Indicates whether or not this option is unused by @c JSDTidyModel.
 *
 *  The implementing application may want to suppress certain built-in
 *  @b libtidy options. Setting this to true will hide instances of this
 *  option from most operations.
 *
 *  If using bindings, make sure you exclude options with this flag set.
 */
@property (nonatomic, assign) BOOL optionIsSuppressed;

/**
 *  Indicates whether or not this option is a list-type option.
 */
@property (nonatomic, assign) BOOL optionIsList;

#pragma mark - Other Public Methods

/**
 *  Given a proposed value, returns a normalized variant thereof, but does
 *  not set it. For example, commas will be added to list items.
 */
- (NSString *)normalizedOptionValue:(NSString *)value;

/**
 *  Applies this option value to another TidyDoc (from @b libtidy) instance.
 *
 *  @param destinationTidyDoc The TidyDoc (from @b libtidy) instance.
 *
 *  @return Returns YES or NO on success or failure.
 */
- (BOOL)applyOptionToTidyDoc:(TidyDoc)destinationTidyDoc;

/**
 *  Sets the option value from another TidyDoc (from @b libtidy) instance.
 *
 *  @param sourceTidyDoc The TidyDoc (from @b libtidy) instance.
 */
- (void)setOptionFromTidyDoc:(TidyDoc)sourceTidyDoc;

/**
 *  Increments the current option value to the next option value in UI order.
 *  There's either a picklist, or there's not. If there's a picklist, then we
 *  cycle through the picklist values. If there's not a picklist, then if
 *  it's @c TidyInteger we will allow changes and not allow values less than 0.
 */
- (void)optionUIValueIncrement;

/**
 *  Decrements the current option value to the previous option value in UI
 *  order. There's either a picklist, or there's not. If there's a picklist,
 *  then we cycle through the picklist values. If there's not a picklist,
 *  then if it's @c TidyInteger we will allow changes and not allow values
 *  less than 0.
 */
- (void)optionUIValueDecrement;

/**
 *  Comparitor for localized sorting and grouping of tidyOptions.
 *  Can be used as a selector for an NSSortDescriptor. This will
 *  ensure that collections (typically an array controller) will
 *  be grouped into categories, sorted within each category,
 *  with a head item being the first item in the category.
 *  @param tidyOption The JSDTidyOption that is being compared.
 */
-(NSComparisonResult)tidyGroupedNameCompare:(JSDTidyOption *)tidyOption;

/**
 *  Comparitor for localized sorting and grouping of tidyOptions.
 *  Can be used as a selector for an NSSortDescriptor. This will
 *  ensure that collections (typically an array controller) will
 *  be grouped into categories, sorted within each category,
 *  with a head item being the first item in the category.
 *  @param tidyOption The JSDTidyOption that is being compared.
 */
-(NSComparisonResult)tidyGroupedHumanNameCompare:(JSDTidyOption *)tidyOption;


@end

