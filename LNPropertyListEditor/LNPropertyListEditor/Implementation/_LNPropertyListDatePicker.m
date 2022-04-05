//
//  _LNPropertyListDatePicker.m
//  LNPropertyListEditor
//
//  Created by Leo Natan on 9/11/19.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import "_LNPropertyListDatePicker.h"
#import "LNPropertyListDatePickerCell.h"
#import "LNPropertyListDatePickerPanel.h"

@interface NSView ()

- (void)geometryInWindowDidChange;

@end

@interface _LNForwardingDatePicker : NSDatePicker
@property (nonatomic, weak) NSResponder* expectedNextResponder;
@end
@implementation _LNForwardingDatePicker

- (NSResponder *)nextResponder
{
	return _expectedNextResponder;
}

@end

@interface _LNPropertyListDatePicker () <LNPropertyListDatePickerPanelDelegate> @end

@implementation _LNPropertyListDatePicker

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		_visualDatePicker = [NSDatePicker new];
		_visualDatePicker.translatesAutoresizingMaskIntoConstraints = NO;
		_visualDatePicker.datePickerStyle = NSDatePickerStyleClockAndCalendar;
		_visualDatePicker.datePickerElements = NSDatePickerElementFlagTimeZone | NSDatePickerElementFlagHourMinuteSecond | NSDatePickerElementFlagYearMonthDay | NSDatePickerElementFlagEra;
		_visualDatePicker.bordered = NO;
		
		_LNForwardingDatePicker* forwardingPicker = [_LNForwardingDatePicker new];
		forwardingPicker.expectedNextResponder = self.nextResponder;
		_textDatePicker = forwardingPicker;
		_textDatePicker.translatesAutoresizingMaskIntoConstraints = NO;
		_textDatePicker.cell = [LNLeadingZerosDatePickerCell new];
		_textDatePicker.bordered = NO;
		
		NSViewController* vc = [NSViewController new];
		LNPropertyListDatePickerPanelBackgroundView* view = [LNPropertyListDatePickerPanelBackgroundView new];
		view.textDatePicker = _textDatePicker;
		view.visualDatePicker = _visualDatePicker;
		vc.view = view;
		[vc.view addSubview:_visualDatePicker];
		[vc.view addSubview:_textDatePicker];
		
		[NSLayoutConstraint activateConstraints:@[
			[vc.view.leadingAnchor constraintEqualToAnchor:_textDatePicker.leadingAnchor],
			[vc.view.topAnchor constraintEqualToAnchor:_textDatePicker.topAnchor],
			[_textDatePicker.bottomAnchor constraintEqualToAnchor:_visualDatePicker.topAnchor],
			[vc.view.leadingAnchor constraintEqualToAnchor:_visualDatePicker.leadingAnchor],
			[vc.view.trailingAnchor constraintEqualToAnchor:_visualDatePicker.trailingAnchor],
			[vc.view.bottomAnchor constraintEqualToAnchor:_visualDatePicker.bottomAnchor],
		]];
		
		_datePickerPanel = [LNPropertyListDatePickerPanel new];
		_datePickerPanel.contentViewController = vc;
		_datePickerPanel.datePickerPanelDelegate = self;
	}
	
	return self;
}

- (BOOL)becomeFirstResponder
{
	_visualDatePicker.dateValue = self.dateValue;
	_visualDatePicker.target = self.target;
	_visualDatePicker.action = self.action;
	[_visualDatePicker sizeToFit];
	
	_textDatePicker.font = self.font;
	_textDatePicker.datePickerStyle = self.datePickerStyle;
	_textDatePicker.datePickerElements = self.datePickerElements;
	_textDatePicker.dateValue = self.dateValue;
	_textDatePicker.target = self.target;
	_textDatePicker.action = self.action;
	[_textDatePicker sizeToFit];
	
	[self.window addChildWindow:_datePickerPanel ordered:NSWindowAbove];
	[self _repositionPanel];

	BOOL rv = [super becomeFirstResponder];
	
	[_datePickerPanel makeKeyWindow];
	[_textDatePicker becomeFirstResponder];
	if(NSApp.currentEvent.type == NSEventTypeLeftMouseDown || NSApp.currentEvent.type == NSEventTypeLeftMouseUp)
	{
		[_textDatePicker.cell _textFieldWithStepperTrackMouse:NSApp.currentEvent inRect:self.bounds ofView:self untilMouseUp:YES];
	}
	
	return rv;
}

- (void)_repositionPanel
{
	if(_datePickerPanel == nil)
	{
		return;
	}
	
	NSScrollView* scrollView = self.enclosingScrollView;
	NSRect selfInScrollView = [scrollView convertRect:self.bounds fromView:self];
	if(selfInScrollView.origin.y < [scrollView.documentView headerView].frame.size.height ||
	   selfInScrollView.origin.y + selfInScrollView.size.height > scrollView.frame.size.height)
	{
		[_datePickerPanel close];
	}
	
	NSRect positionInScreen = [self.window convertRectToScreen:[self convertRect:self.bounds toView:nil]];
	NSRect frame = _datePickerPanel.frame;
	frame.origin = NSMakePoint(positionInScreen.origin.x, positionInScreen.origin.y - frame.size.height + self.bounds.size.height);
	[_datePickerPanel setFrame:frame display:YES];
}

- (void)geometryInWindowDidChange
{
	[super geometryInWindowDidChange];
	
	[self _repositionPanel];
}

- (BOOL)resignFirstResponder
{
	[self.window removeChildWindow:_datePickerPanel];
	[_datePickerPanel close];
	return [super resignFirstResponder];
}

- (void)propertyListDatePickerPanelDidClose:(LNPropertyListDatePickerPanel*)panel
{
	[self.window makeKeyWindow];
	[self.window makeFirstResponder:self.superview];
}

@end
