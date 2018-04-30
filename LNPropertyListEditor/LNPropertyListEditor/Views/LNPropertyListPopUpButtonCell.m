//
//  LNPropertyListPopUpButtonCell.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListPopUpButtonCell.h"

@implementation LNPropertyListPopUpButtonCell

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
	//Set disabled font to appear like a disabled text field.
	if(self.isEnabled == NO)
	{
		NSColor* controlColor = self.backgroundStyle == NSBackgroundStyleDark ? [NSColor valueForKey:@"_alternateDisabledSelectedControlTextColor"] : NSColor.disabledControlTextColor;
		NSMutableAttributedString* attr = self.attributedTitle.mutableCopy;
		[attr addAttribute:NSForegroundColorAttributeName value:controlColor range:NSMakeRange(0, attr.length)];
		title  = attr;
	}
	
	return [super drawTitle:title withFrame:frame inView:controlView];
}

- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag
{
	[self.controlView.window makeFirstResponder:self.controlView.superview];
	
	return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:flag];
}

@end
