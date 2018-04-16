//
//  LNPropertyListRowView.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/16/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListRowView.h"
#import "LNPropertyListCellView.h"

@implementation LNPropertyListRowView
{
	BOOL _mouseIn;
	NSTrackingArea* _trackingArea;
}

- (void)_setButtonsAccourdingToState;
{
	if(self.subviews.count > 0)
	{
		LNPropertyListCellView* cellView = [self viewAtColumn:0];
		cellView.showsControlButtons = self.selected || _mouseIn;
	}
}

- (void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	
	[self _setButtonsAccourdingToState];
}

- (void)ensureTrackingArea
{
	if (_trackingArea == nil)
	{
		_trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
	}
}

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	[self ensureTrackingArea];
	
	if ([[self trackingAreas] containsObject:_trackingArea] == NO)
	{
		[self addTrackingArea:_trackingArea];
	}
}

- (void)mouseEntered:(NSEvent *)event
{
	_mouseIn = YES;
	
	[self _setButtonsAccourdingToState];
}

- (void)mouseExited:(NSEvent *)event
{
	_mouseIn = NO;
	
	[self _setButtonsAccourdingToState];
}

@end
