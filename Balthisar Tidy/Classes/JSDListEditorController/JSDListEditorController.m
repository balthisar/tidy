//
//  JSDListEditorController.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "JSDListEditorController.h"
#import "CommonHeaders.h"

#import "TidyDocument.h"

#import "RSRTVArrayController.h"

@import JSDTidyFramework;

@interface JSDListEditorController ()

/* UI references. */
@property (nonatomic, weak) IBOutlet NSButton *buttonAdd;
@property (nonatomic, weak) IBOutlet NSButton *buttonRemove;
@property (nonatomic, strong) IBOutlet RSRTVArrayController *theArrayController;
@property (nonatomic, weak) IBOutlet NSTableView *theTable;

/* Internal properties. */
@property (nonatomic, strong) NSMutableArray *pitems;


@end


@implementation JSDListEditorController


#pragma mark - Intialization and Deallocation


/*———————————————————————————————————————————————————————————————————*
 * - init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
    if ((self = [super init]))
    {
        self.items = nil;
    }
    
    return self;
}

- (instancetype)initWithString:(NSString *)string
{
    if ( (self = self.init) )
    {
        self.itemsText = string;
    }
    
    return self;
}

- (instancetype)initWithArray:(NSArray<NSString*> *)array
{
    if ( (self = self.init) )
    {
        self.items = array;
    }
    
    return self;
}

/*———————————————————————————————————————————————————————————————————*
 * - dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
    
}


/*———————————————————————————————————————————————————————————————————*
 * - awakeFromNib
 *———————————————————————————————————————————————————————————————————*/
- (void)awakeFromNib
{
    self.theArrayController.rearrange = YES;
}


#pragma mark - Property Accessors (Public)


/*———————————————————————————————————————————————————————————————————*
 * @items
 *———————————————————————————————————————————————————————————————————*/
- (NSArray<NSString*>*)items
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for ( id string in [self.pitems valueForKey:@"string"])
    {
        if ( string != [NSNull null] )
        {
            [result addObject:string];
        }
    }
    
    return result;
}

- (void)setItems:(NSArray<NSString *> *)items
{
    self.pitems = [[NSMutableArray alloc] init];
    
    for (NSString* item in items)
    {
        NSMutableDictionary *record = [NSMutableDictionary dictionaryWithObject:item forKey:@"string"];
        [self.pitems addObject:record];
    }
    [self.theTable reloadData];
}


/*———————————————————————————————————————————————————————————————————*
 * @itemsText
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)itemsText
{
    NSString *result = [self.items componentsJoinedByString:@", "];
    return [result isEqualToString:@""] ? nil : result;
}

- (void)setItemsText:(NSString *)itemsText
{
    if ( !itemsText || [itemsText isEqualToString:@""] )
    {
        self.items = nil;
        return;
    }
    NSArray *array = [[NSMutableArray alloc] initWithArray:[itemsText componentsSeparatedByString:@","]];
    NSMutableArray *trimmed = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSString *item in array)
    {
        [trimmed addObject:[item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }
    self.items = trimmed;
}


#pragma mark - Property Accessors (Category)


@end
