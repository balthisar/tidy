// RSRTVArrayController.h
//
// RSRTV stands for Red Sweater Reordering Table View Controller.
//
// A simple array controller subclass designed to manage row reordering in a table
// view.
//
// Based on code from Apple's DragNDropOutlineView example, which granted
// unlimited modification and redistribution rights, provided Apple not be held legally liable.
//
// Differences between this file and the original are © 2006 Red Sweater Software.
//
// You are granted a non-exclusive, unlimited license to use, reproduce, modify and
// redistribute this source code in any form provided that you agree to NOT hold liable
// Red Sweater Software or Daniel Jalkut for any damages caused by such use.
//

// CLIENT NOTES: To make good use of this class you need to make the following connections
// in Interface Builder:
//
// From RSRTVArrayController -> oTableView
// From oTableView -> dataSource (array controller)
// From oTableview -> delegate (array controller)
//

// Modified by Yannis Chatzikonstantinou on:
// 25-03-2014 for inclusion in the YCHarness framework
// 06-07-2015 for compatibility with Dragndrop messages, through introducing a secondary delegate.
// 10-01-2016 for tidying up the -rearrange (was draggingEnabled) property.
// Modified by Jim Derry on:
// 11/12/2017 for not selecting entire table after dragging a row.

#import <Cocoa/Cocoa.h>

@interface RSRTVArrayController : NSArrayController
{
    IBOutlet NSTableView* oTableView;
}

// Table view drag and drop support
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op;

// Utility methods
-(void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet toIndex:(NSUInteger)index;
-(void)copyObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet toIndex:(NSUInteger)insertIndex;
- (NSIndexSet *)indexSetFromRows:(NSArray *)rows;
- (NSUInteger)rowsAboveRow:(NSUInteger)row inIndexSet:(NSIndexSet *)indexSet;

@property IBOutlet id dragndropDelegate;

@property IBInspectable BOOL rearrange;

@end
