//
//  SWFSemanticVersion.h
//  SWFSemanticVersion
//
//  Created by Samuel Ford on 2/5/14.
//  Copyright (c) 2014 Samuel Ford. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 `SWFSemanticVersion` is an immutable value object that represents a structured version number following the scheme defined by http://semver.org.
 
 Version strings can be roundtripped to and from strings. For example, `[[SWFSemanticVersion semanticVersionFromString:@"0.1.2-rc.1"] description]` yields `0.1.2-rc.1".
 
 Versions can be compared to determine sort order or equality.
 
 ## Examples
 
 Some version strings that this class can represent:
 
 * 0.1.0
 * 1.9.7-p247
 * 1.0.13+build.5476
 * 2.0.47-rc.2+5a3006
 
 ## Comparison Rules
 
 1. Major versions > minor versions > patch versions.
 1. No pre-release suffixes > any pre-release suffixes, otherwise they are compared lexically and numerically.
 1. Build number suffixed are ignored for comparison.
 
 Examples:
 
 * 1.0.0 > 0.9.0
 * 1.1.0 > 1.0.9
 * 1.1.1 > 1.1.0
 * 1.0.0 > 0.9.0-rc1
 * 1.0.0-rc1 > 1.0.0
 * 0.1.0+build1 == 0.1.0
 * 1.0.0-rc1 > 1.0.0+build1
 * 1.0.0-rc1+build1 == 1.0.0-rc1
 * 1.0.0-beta.2 < 1.0.0-beta.11
 
 */
@interface SWFSemanticVersion : NSObject

/** Major version number. Increment for breaking changes. */
@property (nonatomic, readonly, copy) NSNumber * major;

/** Minor version number. Increment for non-breaking enhancements. */
@property (nonatomic, readonly, copy) NSNumber * minor;

/** Patch version number. Increment for non-breaking bug fixes. */
@property (nonatomic, readonly, copy) NSNumber * patch;

/** Pre-release suffix. Optional. */
@property (nonatomic, readonly, copy) NSString * pre;

/** Build suffix. Optional. */
@property (nonatomic, readonly, copy) NSString * build;

/**
 Creates a new `SWFSemanticVersion` by parsing the string passed.
 @param string a semantic version string
 @return a version instance or nil of not a valid version
 */
+ (instancetype)semanticVersionWithString:(NSString *)string;

/**
 Initializes an instance with specified build numbers.
 @param major major number
 @param minor minor number
 @param patch patch number
 @param preRelease pre-release identifier
 @param build build identifier
 @return initialized instance
 */
- (instancetype)initWithMajor:(NSNumber *)major minor:(NSNumber *)minor patch:(NSNumber *)patch pre:(NSString *)pre build:(NSString *)build;

/**
 Returns an `NSComparisonResult` indicating whether version passed is greater than, less than or equal to the current version.
 @param version version to compare to
 @return returns `NSOrderedSame` if identical or `NSOrderedAscending` or `NSOrderedDescending` if the version passed is greater than or less than the current version repsectively
 */
- (NSComparisonResult)compare:(SWFSemanticVersion *)version;

@end
