//
//  LNPropertyListOutlineView.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/16/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListOutlineView.h"

@implementation LNPropertyListOutlineView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
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

@end
