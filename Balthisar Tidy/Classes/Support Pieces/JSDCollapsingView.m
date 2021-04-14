//
//  JSDCollapsingView.m
//
//  Copyright © 2003-2021 by Jim Derry. All rights reserved.
//

#import "JSDCollapsingView.h"


@interface JSDCollapsingView ()

/* Will be used to collapse and uncollapse the view. */
@property (nonatomic, strong, readwrite) NSLayoutConstraint *constraint;

/* Redefine for internal use. */
@property (nonatomic, assign, readwrite) NSRect originalFrame;

@end


@implementation JSDCollapsingView

@synthesize collapsed = _collapsed;


#pragma mark - Instantiation


/*———————————————————————————————————————————————————————————————————*
 * - initWithFrame:
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)initWithFrame:(NSRect)frameRect
{
    if ( (self = [super initWithFrame:frameRect]) )
    {
        [self setupInitialValues];
    }
    
    return self;
    
}


/*———————————————————————————————————————————————————————————————————*
 * - initWithCoder:
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ( (self = [super initWithCoder:decoder]) )
    {
        [self setupInitialValues];
    }
    
    return self;
}


/*———————————————————————————————————————————————————————————————————*
 * - init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
    if ( (self = [super init]) )
    {
        [self setupInitialValues];
    }
    
    return self;
}


/*———————————————————————————————————————————————————————————————————*
 * - setupInitialValues
 *———————————————————————————————————————————————————————————————————*/
- (void)setupInitialValues
{
    self.panelNumber = 0;
    self.priorityHidden = 950;
    self.collapsed = NO;
    self.constraint = [NSLayoutConstraint constraintWithItem:self
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:1.0
                                                    constant:0.0];
    
    self.constraint.priority = self.priorityHidden;
    self.constraint.active = NO;
    
    self.wantsLayer = YES;
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
}


#pragma mark - Property Accessors


/*———————————————————————————————————————————————————————————————————*
 * @collapsed
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)isCollapsed
{
    return _collapsed;
}

- (void)setCollapsed:(BOOL)collapsed
{
    if ( NSIsEmptyRect( self.originalFrame ) )
    {
        self.originalFrame = self.frame;
    }
    
    _collapsed = collapsed;
    
    if (collapsed)
    {
        self.constraint.priority = self.priorityHidden;
        self.constraint.active = YES;
        self.hidden = YES;
    }
    else
    {
        self.constraint.priority = 100;
        self.constraint.active = NO;
        self.hidden = NO;
    }
}


@end
