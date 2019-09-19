//
//  LNPropertyListDatePickerCell.mm
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/29/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListDatePickerCell.h"
#import <objc/runtime.h>

static NSDatePickerCell* __strong __drawingDatePickerCell;

@interface NSDatePickerCell ()

- (void)_setForcesLeadingZeroes:(BOOL)arg1;
- (NSColor*)_textColorBasedOnEnabledState;

@end

@interface NSBezierPath (LNPropertyListEditorDatePickerCustomization) @end

@implementation NSBezierPath (LNPropertyListEditorDatePickerCustomization)

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Method m1 = class_getClassMethod(NSBezierPath.class, @selector(__ln_bezierPathWithRoundedRect:xRadius:yRadius:));
		Method m2 = class_getClassMethod(NSBezierPath.class, @selector(bezierPathWithRoundedRect:xRadius:yRadius:));
		method_exchangeImplementations(m1, m2);
	});
}

+ (NSBezierPath *)__ln_bezierPathWithRoundedRect:(NSRect)rect xRadius:(CGFloat)xRadius yRadius:(CGFloat)yRadius
{
	if(__drawingDatePickerCell != nil)
	{
//		[[__drawingDatePickerCell._textColorBasedOnEnabledState blendedColorWithFraction:0.6 ofColor:NSColor.alternateSelectedControlColor] set];
	}
	
	NSBezierPath* rv = [self __ln_bezierPathWithRoundedRect:rect xRadius:xRadius yRadius:yRadius];
	
	return rv;
}

@end

@implementation LNLeadingZerosDatePickerCell

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		[self _setForcesLeadingZeroes:YES];
	}
	
	return self;
}

@end

@implementation LNPropertyListDatePickerCell

- (BOOL)_isFirstResponder
{
	return self.controlView.window.firstResponder == self.controlView;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	__drawingDatePickerCell = self;
	if(self._isFirstResponder)
	{
		[NSColor.textBackgroundColor setFill];
		[[NSBezierPath bezierPathWithRect:cellFrame] fill];
	}
	
	[super drawWithFrame:cellFrame inView:controlView];
	
	__drawingDatePickerCell = nil;
}

//This is faster than setting the text color when the background color changes.
- (NSColor*)_textColorBasedOnEnabledState
{
	
	return self.isEnabled ? self.backgroundStyle == NSBackgroundStyleEmphasized ? self._isFirstResponder ? NSColor.controlTextColor : NSColor.alternateSelectedControlTextColor : NSColor.controlTextColor : self.backgroundStyle == NSBackgroundStyleEmphasized ? [NSColor valueForKey:@"_alternateDisabledSelectedControlTextColor"] : NSColor.disabledControlTextColor;
}

- (BOOL)_shouldShowFocusRingInView:(id)arg1
{
	return YES;
}

@end
