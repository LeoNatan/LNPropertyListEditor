//
//  LNPropertyListCellView.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListCellView.h"
@import QuartzCore;
@import ObjectiveC;

@interface LNPropertyListCellView () <NSTextFieldDelegate> @end

@implementation LNPropertyListCellView

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.wantsLayer = YES;
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	self.layer.borderWidth = 2.0;
	self.layer.borderColor = NSColor.clearColor.CGColor;
	
	objc_setAssociatedObject(self.typeButton.menu, "button", self.typeButton, OBJC_ASSOCIATION_ASSIGN);
	
	if(self.buttonsConstraint)
	{
		[NSLayoutConstraint deactivateConstraints:@[self.buttonsConstraint]];
	}
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	
	self.plusButton.hidden = self.minusButton.hidden = YES;
	if(self.buttonsConstraint)
	{
		[NSLayoutConstraint deactivateConstraints:@[self.buttonsConstraint]];
	}
}

- (void)setControlWithString:(NSString*)str setToolTip:(BOOL)setToolTip
{
	if(self.typeButton)
	{
		[self.typeButton selectItemWithTitle:str];
	}
	else
	{
		self.textField.stringValue = str;
	}
	
	if(setToolTip)
	{
		self.toolTip = str;
	}
}

- (void)setControlWithBoolean:(BOOL)boolean
{
	[self.typeButton selectItemAtIndex:(NSInteger)boolean];
}

- (void)flashError
{
	CABasicAnimation* flashAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
	flashAnimation.fromValue = (__bridge id)NSColor.clearColor.CGColor;
	flashAnimation.toValue = (__bridge id)NSColor.systemRedColor.CGColor;
	flashAnimation.duration = 0.25;
	flashAnimation.autoreverses = YES;
	flashAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	flashAnimation.fillMode = kCAFillModeForwards;
	flashAnimation.removedOnCompletion = YES;
	
	[self.layer addAnimation:flashAnimation forKey:@"backgroundColor"];
}

- (void)setShowsControlButtons:(BOOL)showsControlButtons addButtonEnabled:(BOOL)addButtonEnabled deleteButtonEnabled:(BOOL)deleteButtonEnabled
{
	_showsControlButtons = showsControlButtons && (addButtonEnabled || deleteButtonEnabled);
	
	self.plusButton.hidden = self.minusButton.hidden = !_showsControlButtons;
	self.buttonsConstraint.active = _showsControlButtons;
	
	self.plusButton.enabled = addButtonEnabled;
	self.minusButton.enabled = deleteButtonEnabled;
}

- (void)setControlEditable:(BOOL)editable
{
	self.textField.selectable = self.textField.editable = editable;
	_typeButton.enabled = editable;
	
	NSColor* controlColor = editable ? NSColor.textColor : NSColor.disabledControlTextColor;
	
	self.textField.textColor = controlColor;
}

@end
