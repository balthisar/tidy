//
//  MGSAutoCompleteDelegate.h
//  Fragaria
//
//  Created by Viktor Lidholt on 4/12/13.
//
//

#import <Foundation/Foundation.h>


/**
 *  The MGSAutoCompleteDelegate defines an interface for allowing a delegate to
 *  return a list of suitable autocomplete choices.
 **/
@protocol MGSAutoCompleteDelegate <NSObject>

- (NSArray<NSString *> *) completions;   ///< A dictionary of words that can be used for autocompletion.

@end
