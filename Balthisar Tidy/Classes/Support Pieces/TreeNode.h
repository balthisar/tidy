//
//  TreeNode.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (MyExtensions)
- (BOOL)containsObjectIdenticalTo: (id)object;
@end

@interface NSMutableArray (MyExtensions)
- (void) insertObjectsFromArray:(NSArray *)array atIndex:(int)index;
@end


@interface TreeNodeData : NSObject {
}
- (NSComparisonResult)compare:(TreeNodeData*)other;
@end

@interface TreeNode : NSObject {
@protected
    TreeNode *nodeParent;
    TreeNodeData *nodeData;
    NSMutableArray *nodeChildren;
}

+ (id)treeNodeWithData:(TreeNodeData*)data;
- (id)initWithData:(TreeNodeData*)data parent:(TreeNode*)parent children:(NSArray*)children;

- (void)setNodeData:(TreeNodeData*)data;
- (TreeNodeData*)nodeData;

- (void)setNodeParent:(TreeNode*)parent;
- (TreeNode*)nodeParent;

- (void)insertChild:(TreeNode*)child atIndex:(int)index;
- (void)insertChildren:(NSArray*)children atIndex:(int)index;
- (void)removeChild:(TreeNode*)child;
- (void)removeFromParent;

- (NSUInteger)indexOfChild:(TreeNode*)child;
- (NSUInteger)indexOfChildIdenticalTo:(TreeNode*)child;

- (NSUInteger)numberOfChildren;
- (NSArray*)children;
- (TreeNode*)firstChild;
- (TreeNode*)lastChild;
- (TreeNode*)childAtIndex:(NSUInteger)index;

- (BOOL)isDescendantOfNode:(TreeNode*)node;
    // returns YES if 'node' is an ancestor.

- (BOOL)isDescendantOfNodeInArray:(NSArray*)nodes;
    // returns YES if any 'node' in the array 'nodes' is an ancestor of ours.

- (void)recursiveSortChildren;
    // sort children using the compare: method in TreeNodeData

// Returns the minimum nodes from 'allNodes' required to cover the nodes in 'allNodes'.
// This methods returns an array containing nodes from 'allNodes' such that no node in
// the returned array has an ancestor in the returned array.
+ (NSArray *)minimumNodeCoverFromNodesInArray: (NSArray *)allNodes;

@end
