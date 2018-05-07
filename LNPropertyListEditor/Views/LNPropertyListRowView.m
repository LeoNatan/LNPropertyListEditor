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

- (void)updateEditButtons;
{
	if(self.subviews.count > 0)
	{
		LNPropertyListCellView* cellView = [self viewAtColumn:0];
		
		BOOL addButtonEnabled = [self.editor canInsertAtNode:self.node];
		BOOL deleteButtonEnabled = [self.editor canDeleteNode:self.node];
		
		[cellView setShowsControlButtons:self.selected || _mouseIn addButtonEnabled:addButtonEnabled deleteButtonEnabled:deleteButtonEnabled];
	}
}

- (void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	
	[self updateEditButtons];
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
	
	[self updateEditButtons];
}

- (void)mouseExited:(NSEvent *)event
{
	_mouseIn = NO;
	
	[self updateEditButtons];
}

@end
