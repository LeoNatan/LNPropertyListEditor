//
//  LNPropertyListDatePickerPanel.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 9/11/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import "LNPropertyListDatePickerPanel.h"

@implementation LNPropertyListDatePickerPanelBackgroundView

- (CGPathRef)_pathAroundView
{
	const CGFloat radius = 4;
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, CGRectGetMinX(self.textDatePicker.frame), CGRectGetMaxY(self.textDatePicker.frame) - radius);
	CGPathAddArcToPoint(path, NULL, CGRectGetMinX(self.textDatePicker.frame), CGRectGetMaxY(self.textDatePicker.frame),
						CGRectGetMinX(self.textDatePicker.frame) + radius, CGRectGetMaxY(self.textDatePicker.frame), radius);
	CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(self.textDatePicker.frame) - radius, CGRectGetMaxY(self.textDatePicker.frame));
	CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(self.textDatePicker.frame), CGRectGetMaxY(self.textDatePicker.frame),
						CGRectGetMaxX(self.textDatePicker.frame), CGRectGetMaxY(self.textDatePicker.frame) - radius, radius);
	CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(self.textDatePicker.frame), CGRectGetMaxY(self.visualDatePicker.frame) + radius);
	CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(self.textDatePicker.frame), CGRectGetMaxY(self.visualDatePicker.frame),
						CGRectGetMaxX(self.textDatePicker.frame) + radius, CGRectGetMaxY(self.visualDatePicker.frame), radius);
	CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(self.visualDatePicker.frame) - radius, CGRectGetMaxY(self.visualDatePicker.frame));
	CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(self.visualDatePicker.frame), CGRectGetMaxY(self.visualDatePicker.frame),
						CGRectGetMaxX(self.visualDatePicker.frame), CGRectGetMaxY(self.visualDatePicker.frame) - radius, radius);
	CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(self.visualDatePicker.frame), CGRectGetMinY(self.visualDatePicker.frame) + radius);
	CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(self.visualDatePicker.frame), CGRectGetMinY(self.visualDatePicker.frame),
						CGRectGetMaxX(self.visualDatePicker.frame) - radius, CGRectGetMinY(self.visualDatePicker.frame), radius);
	CGPathAddLineToPoint(path, NULL, CGRectGetMinX(self.visualDatePicker.frame) + radius, CGRectGetMinY(self.visualDatePicker.frame));
	CGPathAddArcToPoint(path, NULL, CGRectGetMinX(self.visualDatePicker.frame), CGRectGetMinY(self.visualDatePicker.frame),
						CGRectGetMinX(self.visualDatePicker.frame), CGRectGetMinY(self.visualDatePicker.frame) + radius, radius);
	CGPathCloseSubpath(path);
	
	return path;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[NSColor.controlBackgroundColor setFill];
	
	CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
	
	CGContextAddPath(ctx, self._pathAroundView);
	CGContextFillPath(ctx);
}

@end

@implementation LNPropertyListDatePickerPanel

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag
{
	self = [super initWithContentRect:contentRect styleMask:NSWindowStyleMaskBorderless backing:backingStoreType defer:flag];
	
	if(self)
	{
		self.releasedWhenClosed = NO;
		self.opaque = NO;
		self.hasShadow = YES;
		self.backgroundColor = NSColor.clearColor;
		self.hidesOnDeactivate = NO;
	}
	
	return self;
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (void)resignKeyWindow
{
	[self close];
}

- (void)close
{
	if(self.isVisible == NO)
	{
		return;
	}
	
	[super close];
	
	[self.datePickerPanelDelegate propertyListDatePickerPanelDidClose:self];
}

- (void)setIsVisible:(BOOL)flag
{
	if(self.isVisible == flag)
	{
		return;
	}
	
	[super setIsVisible:flag];
}

- (void)setParentWindow:(NSWindow *)parentWindow
{
	[super setParentWindow:parentWindow];
}

- (void)dealloc
{
	
}

@end
