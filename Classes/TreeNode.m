/*
	TreeNode.m
	Copyright (c) 2001-2002, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

        Generic Tree node and data structures (TreeNode, and TreeNodeData).
	
	
	TreeNode is a node in a doubly linked tree data structure.  TreeNode's have weak references to their
        parent (to avoid retain cycles since parents retain their children).  Each node has 0 or more children
        and a reference to a piece of TreeNodeData data. The TreeNode provides method to manipulate and extract
        structural information about a tree.  For instance, TreeNode implements: insertChild:atIndex:,
        removeChild:, isDescendantOfNode:, and other useful operations on tree nodes.
	TreeNode and TreeNodeData provide the structure and common functionality of trees,
        and are expected to be subclassed.
*/

#import "TreeNode.h"


@implementation NSArray (MyExtensions)

- (BOOL) containsObjectIdenticalTo: (id)obj { 
    return [self indexOfObjectIdenticalTo: obj]!=NSNotFound; 
}

@end

@implementation NSMutableArray (MyExtensions)

- (void) insertObjectsFromArray:(NSArray *)array atIndex:(int)index {
    NSObject *entry = nil;
    NSEnumerator *enumerator = [array objectEnumerator];
    while ((entry=[enumerator nextObject])) {
        [self insertObject:entry atIndex:index++];
    }
}

@end



@implementation TreeNodeData 

- (NSComparisonResult)compare:(TreeNodeData *)other {
    // Return anything, it is expected this will be overridden by subclasses.
    // For instance, SimpleTreeData compares names!
    return NSOrderedAscending;
}

@end

@implementation TreeNode

+ (id)treeNodeWithData:(TreeNodeData*)data {
    return [[[TreeNode alloc] initWithData: data  parent:nil children:[NSArray array]] autorelease]; 
}

- (id)initWithData:(TreeNodeData*)data parent:(TreeNode*)parent children:(NSArray*)children {
    self = [super init];
    if (self==nil) return nil;
    
    nodeData = [data retain];
    nodeChildren = [[NSMutableArray arrayWithArray:children] retain];
    nodeParent = parent;
    
    return self;
}

- (void)dealloc {
    [nodeData release];
    [nodeChildren release];
    nodeData = nil;
    nodeChildren = nil;
    [super dealloc];
}

// ================================================================
// Methods used to manage a node and its children.
// ================================================================

- (void)setNodeData:(TreeNodeData*)data { 
    [nodeData release]; 
    nodeData = [data retain]; 
}

- (TreeNodeData*)nodeData { 
    return nodeData; 
}

- (void)setNodeParent:(TreeNode*)parent {
    nodeParent = parent; 
}

- (TreeNode*)nodeParent { 
    return nodeParent; 
}

- (void)insertChild:(TreeNode*)child atIndex:(int)index {
    [nodeChildren insertObject:child atIndex:index];
    [child setNodeParent: self];
}

- (void)insertChildren:(NSArray*)children atIndex:(int)index {
    [nodeChildren insertObjectsFromArray: children atIndex: index];
    [children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:self];
}

- (void)_removeChildrenIdenticalTo:(NSArray*)children {
    TreeNode *child;
    NSEnumerator *childEnumerator = [children objectEnumerator];
    [children makeObjectsPerformSelector:@selector(setNodeParent:) withObject:nil];
    while ((child=[childEnumerator nextObject])) {
        [nodeChildren removeObjectIdenticalTo:child];
    }
}

- (void)removeChild:(TreeNode*)child {
    int index = [self indexOfChild: child];
    if (index!=NSNotFound) {
        [self _removeChildrenIdenticalTo: [NSArray arrayWithObject: [self childAtIndex:index]]];
    }
}

- (void)removeFromParent {
    [[self nodeParent] removeChild:self];
}

- (int)indexOfChild:(TreeNode*)child {
    return [nodeChildren indexOfObject:child];
}

- (int)indexOfChildIdenticalTo:(TreeNode*)child {
    return [nodeChildren indexOfObjectIdenticalTo:child];
}

- (int)numberOfChildren {
    return [nodeChildren count];
}

- (NSArray*)children {
    return [NSArray arrayWithArray: nodeChildren];
}

- (TreeNode*)firstChild {
    return [nodeChildren objectAtIndex:0];
}

- (TreeNode*)lastChild {
    return [nodeChildren lastObject];
}

- (TreeNode*)childAtIndex:(int)index {
    return [nodeChildren objectAtIndex:index];
}

- (BOOL)isDescendantOfNode:(TreeNode*)node {
    // returns YES if 'node' is an ancestor.
    // Walk up the tree, to see if any of our ancestors is 'node'.
    TreeNode *parent = self;
    while(parent) {
        if(parent==node) return YES;
        parent = [parent nodeParent];
    }
    return NO;
}

- (BOOL)isDescendantOfNodeInArray:(NSArray*)nodes {
    // returns YES if any 'node' in the array 'nodes' is an ancestor of ours.
    // For each node in nodes, if node is an ancestor return YES.  If none is an
    // ancestor, return NO.
    NSEnumerator *nodeEnum = [nodes objectEnumerator];
    TreeNode *node = nil;
    while((node=[nodeEnum nextObject])) {
        if([self isDescendantOfNode:node]) return YES;
    }
    return NO;
}

- (void)recursiveSortChildren {
    [nodeChildren sortUsingSelector:@selector(compare:)];
    [nodeChildren makeObjectsPerformSelector: @selector(recursiveSortChildren)];
}

- (NSString*)description {
    // Return something that will be useful for debugging.
    return [NSString stringWithFormat: @"{%@}", nodeData];
}

// Returns the minimum nodes from 'allNodes' required to cover the nodes in 'allNodes'.
// This methods returns an array containing nodes from 'allNodes' such that no node in
// the returned array has an ancestor in the returned array.

// There are better ways to compute this, but this implementation should be efficient for our app.
+ (NSArray *) minimumNodeCoverFromNodesInArray: (NSArray *)allNodes {
    NSMutableArray *minimumCover = [NSMutableArray array];
    NSMutableArray *nodeQueue = [NSMutableArray arrayWithArray:allNodes];
    TreeNode *node = nil;
    while ([nodeQueue count]) {
        node = [nodeQueue objectAtIndex:0];
        [nodeQueue removeObjectAtIndex:0];
        while ( [node nodeParent] && [nodeQueue containsObjectIdenticalTo:[node nodeParent]] ) {
            [nodeQueue removeObjectIdenticalTo: node];
            node = [node nodeParent];
        }
        if (![node isDescendantOfNodeInArray: minimumCover]) [minimumCover addObject: node];
        [nodeQueue removeObjectIdenticalTo: node];
    }
    return minimumCover;
}

- (NSComparisonResult)compare:(TreeNode*)node {
    // Compare nodes to each other by comparing the data part.
    return [nodeData compare:[node nodeData]];
}

@end
