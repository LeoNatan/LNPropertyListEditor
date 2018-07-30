//
//  LNPropertyListDatePickerCell.mm
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/29/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListDatePickerCell.h"
#import <objc/runtime.h>

static thread_local BOOL __drawingDatePicker;

@interface NSDatePickerCell ()

- (void)_setForcesLeadingZeroes:(BOOL)arg1;

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
	if(__drawingDatePicker == YES)
	{
		[[NSColor.alternateSelectedControlColor highlightWithLevel:0.35] set];
	}
	
	NSBezierPath* rv = [self __ln_bezierPathWithRoundedRect:rect xRadius:xRadius yRadius:yRadius];
	
	return rv;
}

@end

@implementation LNPropertyListDatePickerCell

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		[self _setForcesLeadingZeroes:YES];
	}
	
	return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	__drawingDatePicker = YES;
	[super drawWithFrame:cellFrame inView:controlView];
	__drawingDatePicker = NO;
}

//This is faster than setting the text color when the background color changes.
- (NSColor*)_textColorBasedOnEnabledState
{
	return self.isEnabled ? self.backgroundStyle == NSBackgroundStyleEmphasized ? NSColor.alternateSelectedControlTextColor : NSColor.controlTextColor : self.backgroundStyle == NSBackgroundStyleEmphasized ? [NSColor valueForKey:@"_alternateDisabledSelectedControlTextColor"] : NSColor.disabledControlTextColor;

}

@end
