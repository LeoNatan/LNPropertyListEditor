//
//  LNPropertyListOutlineView.m
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/16/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import "LNPropertyListOutlineView.h"

@implementation LNPropertyListOutlineView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.enclosingScrollView.wantsLayer = YES;
	self.enclosingScrollView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (void)drawGridInClipRect:(NSRect)clipRect
{
	NSRect lastRowRect = [self rectOfRow:[self numberOfRows] - 1];
	NSRect myClipRect = NSMakeRect(0, 0, lastRowRect.size.width, NSMaxY(lastRowRect));
	NSRect finalClipRect = NSIntersectionRect(clipRect, myClipRect);
	[super drawGridInClipRect:finalClipRect];
}

- (void)layout
{
    [super layout];
    
    if((self.tableColumns.lastObject.resizingMask & NSTableColumnAutoresizingMask) == NSTableColumnAutoresizingMask)
    {
        [self sizeLastColumnToFit];
    }
}

@end
