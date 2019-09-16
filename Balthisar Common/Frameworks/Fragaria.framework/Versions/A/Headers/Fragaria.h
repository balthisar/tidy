/*
 *  Fragaria.h
 *  Fragaria
 *
 *  Created by Jonathan on 30/04/2010.
 *  Copyright 2010 mugginsoft.com. All rights reserved.
 *
 */

#undef FRAGARIA_PRIVATE
#import "FragariaMacros.h"
#import "FragariaUtilities.h"

#import "MGSBreakpointDelegate.h"           
#import "MGSDragOperationDelegate.h"        
#import "MGSFragariaTextViewDelegate.h"     
#import "MGSAutoCompleteDelegate.h"

#import "MGSFragariaView.h"
#import "MGSSyntaxError.h"
#import "MGSTextView.h"
#import "MGSTextView+MGSTextActions.h"
#import "MGSTextView+MGSDragging.h"

#import "MGSSyntaxController.h"
#import "MGSParserFactory.h"
#import "MGSSyntaxParserClient.h"
#import "MGSSyntaxAwareEditor.h"
#import "MGSSyntaxParser.h"
#import "MGSClassicFragariaParserFactory.h"

#import "MGSColourScheme.h"
#import "MGSMutableColourScheme.h"
#import "MGSMutableColourSchemeFromPlistTransformer.h"

#import "NSTextStorage+Fragaria.h"
#import "MGSMutableSubstring.h"
