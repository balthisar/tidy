//
//  MGSClassicFragariaParserFactory.h
//  Fragaria
//
//  Created by Daniele Cattaneo on 27/12/2018.
//

#import <Foundation/Foundation.h>
#import "FragariaMacros.h"
#import "MGSParserFactory.h"

NS_ASSUME_NONNULL_BEGIN


/** A parser factory class used to load classic Fragaria syntax definition files.
 *
 *  An instance of this class is already loaded automatically by MGSSyntaxController
 *  in order to load the syntax definitions placed in the default locations.
 *  If desired, additional syntax definitions can be loaded from custom
 *  locations by creating another instance of this class and registering it via
 *  MGSSyntaxController.
 *
 *  This parser factory class is also capable of loading localized user-facing syntax
 *  group names from "SyntaxGroupNames.strings" files.
 *
 *  ## Default locations for syntax definition files and syntax group name files
 *
 *  - Syntax definitions from:
 *     - The "Resources/Syntax Definitions" directory in the Fragaria framework bundle
 *     - The "Resources/Syntax Definitions" directory in the current application bundle
 *     - The "Syntax Definitions" directory inside the "Application Support" directory of
 *       the current application.
 *  - Syntax group name files from:
 *     - The Resources directory of the Fragaria framework bundle (the built-in syntax
 *       group names)
 *     - The Resources directory of the current application bundle
 *     - The "Syntax Definitions" directory inside the "Application Support" directory of
 *       the current application.
 *
 *  Note that only the "SyntaxGroupNames.strings" files inside a bundle can also be
 *  located in a .lproj subdirectory in order to provide localized names. */

@interface MGSClassicFragariaParserFactory : NSObject <MGSParserFactory>


/** Returns a parser factory by loading the syntax definitions from
 *  the default locations.
 *  @warning Never register a new parser factory initialized through this
 *    method, as MGSSyntaxController already does this automatically. */
- (instancetype)init FRAGARIA_PUB_UNAVAIL_MSG("Don't invoke this, MGSSyntaxController already does it for you!");

/** Returns a parser factory which loads syntax definitions from the
 *  "Resources/Syntax Definitions" directory in the specified bundle and
 *  syntax group names from a localized resource named "SyntaxGroupNames.strings".
 *  @param bundles The bundle where to search for syntax definitions and group names.
 *  @note All built-in syntax group names are loaded as well, but the names loaded
 *     from the specified bundles always take precedence. */
- (instancetype)initWithSyntaxDefinitionsInBundles:(NSArray <NSBundle *> *)bundles;

/** Returns a parser factory which loads syntax definitions from the
 *  specified directories and syntax group names from strings files named
 *  "SyntaxGroupNames.strings" and located in the same directories.
 *  @param searchPaths An array of directories where to search syntax definition
 *    files and syntax group name files.
 *  @note All built-in syntax group names are loaded as well, but the names loaded
 *     from the specified paths always take precedence. */
- (instancetype)initWithSyntaxDefinitionDirectories:(NSArray <NSURL *> *)searchPaths;

/** Returns a parser factory which loads the specified syntax definition
 *  files and the specified syntax group name files.
 *  @param f An array of syntax definition file URLs.
 *  @param strf An array of syntax group name strings file URLs.
 *  @note When using this method, the default syntax group names are not loaded.
 *    In general, prefer using the other initializers when possible. */
- (instancetype)initWithSyntaxDefinitionFiles:(NSArray <NSURL *> *)f syntaxGroupNameFiles:(NSArray <NSURL *> *)strf NS_DESIGNATED_INITIALIZER;


@end


NS_ASSUME_NONNULL_END
