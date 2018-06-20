//
//  LNPropertyListPopUpButtonCell.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/26/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListPopUpButtonCell.h"

static NSColor* __enabledTextColor;
static NSColor* __enabledTextColorHighlight;
static NSColor* __disabledTextColor;
static NSColor* __disabledTextColorHighlight;
static NSAppearance* __darkAppearanceCache;

@implementation LNPropertyListPopUpButtonCell

+ (void)load
{
	__enabledTextColor = NSColor.labelColor;
	__enabledTextColorHighlight = NSColor.alternateSelectedControlTextColor;
	__disabledTextColor = NSColor.disabledControlTextColor;
	__disabledTextColorHighlight = [NSColor valueForKey:@"_alternateDisabledSelectedControlTextColor"];
	__darkAppearanceCache = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{	
	BOOL isHighlited = self.backgroundStyle == NSBackgroundStyleDark;
	//All this to get the damn colors to match a text field. Ridiculous
	NSColor* controlColor = self.isEnabled ? (isHighlited ? __enabledTextColorHighlight : (controlView.effectiveAppearance == __darkAppearanceCache ? NSColor.whiteColor : __enabledTextColor)) : (isHighlited ? __disabledTextColorHighlight : __disabledTextColor);
	NSMutableAttributedString* attr = self.attributedTitle.mutableCopy;
	[attr addAttribute:NSForegroundColorAttributeName value:controlColor range:NSMakeRange(0, attr.length)];
	
	return [super drawTitle:attr withFrame:frame inView:controlView];
}

- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag
{
	[self.controlView.window makeFirstResponder:self.controlView.superview];
	
	return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:flag];
}

@end
