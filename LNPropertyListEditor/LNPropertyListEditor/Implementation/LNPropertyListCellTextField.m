//
//  LNPropertyListCellTextField.m
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/30/21.
//  Copyright © 2021 Leo Natan. All rights reserved.
//

#import "LNPropertyListCellTextField.h"

@implementation LNPropertyListCellTextField

- (NSView *)hitTest:(NSPoint)point
{
	if((self.currentEditor == nil || self.window.firstResponder != self.currentEditor) &&
	   (NSApp.currentEvent.type == NSEventTypeRightMouseDown || NSApp.currentEvent.type == NSEventTypeRightMouseUp))
	{
		return nil;
	}
	
	return [super hitTest:point];
}

- (BOOL)becomeFirstResponder
{
	return [super becomeFirstResponder];
}

@end
