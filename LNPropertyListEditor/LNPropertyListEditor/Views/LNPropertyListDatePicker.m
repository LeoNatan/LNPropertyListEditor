//
//  LNPropertyListDatePicker.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/30/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListDatePicker.h"
#import "LNPropertyListDatePickerCell.h"

static NSPopover* __LNPropertyListDatePickerPopover;
static NSDatePicker* __LNPropertyListPopoverDatePicker;

@interface LNPropertyListDatePicker ()

@property (class, nonatomic, readonly, retain) NSDatePicker* __datePicker;
@property (class, nonatomic, readonly, retain) NSPopover* __datePickerPopover;

@end

@interface _LNPropertyListDatePickerInnerCell : NSCell

@property (nonatomic, copy) NSArray<NSCell*>* childCells;

@end

@implementation _LNPropertyListDatePickerInnerCell

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	[self.childCells enumerateObjectsUsingBlock:^(NSCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[obj setBackgroundStyle:backgroundStyle];
	}];
}

- (void)setHighlighted:(BOOL)highlighted
{}

@end

@interface _LNPropertyListDatePicker : NSDatePicker @end

@implementation _LNPropertyListDatePicker

- (BOOL)becomeFirstResponder
{
	BOOL rv = [super becomeFirstResponder];
	
	if(rv)
	{
		LNPropertyListDatePicker.__datePicker.dateValue = self.dateValue;
		LNPropertyListDatePicker.__datePicker.target = self.target;
		LNPropertyListDatePicker.__datePicker.action = self.action;
		
		[LNPropertyListDatePicker.__datePickerPopover showRelativeToRect:self.bounds ofView:self preferredEdge:NSRectEdgeMinY];
		
	}
	
	return rv;
}

- (BOOL)resignFirstResponder
{
	BOOL rv = [super resignFirstResponder];
	
	if(rv)
	{
		[self unbind:NSValueBinding];
		LNPropertyListDatePicker.__datePicker.target = nil;
		LNPropertyListDatePicker.__datePicker.action = nil;
		
		[LNPropertyListDatePicker.__datePickerPopover close];
	}
	
	return rv;
}

@end


IB_DESIGNABLE
@implementation LNPropertyListDatePicker
{
	NSDatePicker* _datePicker;
	NSDatePicker* _timePicker;
}

+ (NSDatePicker*)__datePicker
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__LNPropertyListPopoverDatePicker = [NSDatePicker new];
		__LNPropertyListPopoverDatePicker.datePickerStyle = NSClockAndCalendarDatePickerStyle;
		__LNPropertyListPopoverDatePicker.datePickerElements = NSTimeZoneDatePickerElementFlag | NSYearMonthDayDatePickerElementFlag | NSEraDatePickerElementFlag;
		__LNPropertyListPopoverDatePicker.bordered = NO;
		__LNPropertyListPopoverDatePicker.drawsBackground = NO;
		[__LNPropertyListPopoverDatePicker sizeToFit];
	});
	
	return __LNPropertyListPopoverDatePicker;
}

+ (NSPopover*)__datePickerPopover
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSViewController* vc = [NSViewController new];
		vc.view = LNPropertyListDatePicker.__datePicker;
		
		__LNPropertyListDatePickerPopover = [NSPopover new];
		__LNPropertyListDatePickerPopover.contentViewController = vc;
	});
	
	return __LNPropertyListDatePickerPopover;
}

- (void)prepareForInterfaceBuilder
{
	_timePicker.dateValue = _datePicker.dateValue = [NSDate date];
}

- (void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	
	[_datePicker setEnabled:enabled];
	[_timePicker setEnabled:enabled];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSFont* font = [NSFont monospacedDigitSystemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightRegular];
	
	_datePicker = [_LNPropertyListDatePicker new];
	_datePicker.cell = [LNPropertyListDatePickerCell new];
	_datePicker.font = font;
	_datePicker.datePickerStyle = NSTextFieldDatePickerStyle;
	_datePicker.datePickerElements = NSYearMonthDayDatePickerElementFlag | NSEraDatePickerElementFlag;
	_datePicker.bordered = NO;
	_datePicker.drawsBackground = NO;
	_datePicker.translatesAutoresizingMaskIntoConstraints = NO;
	_datePicker.target = self;
	_datePicker.action = @selector(_internalDatePickerValueChanged:);
	
	_timePicker = [NSDatePicker new];
	_timePicker.cell = [LNPropertyListDatePickerCell new];
	_timePicker.font = font;
	_timePicker.datePickerStyle = NSTextFieldDatePickerStyle;
	_timePicker.datePickerElements = NSHourMinuteSecondDatePickerElementFlag | NSTimeZoneDatePickerElementFlag;
	_timePicker.bordered = NO;
	_timePicker.drawsBackground = NO;
	_timePicker.translatesAutoresizingMaskIntoConstraints = NO;
	_timePicker.target = self;
	_timePicker.action = @selector(_internalDatePickerValueChanged:);
	
	_LNPropertyListDatePickerInnerCell* cell = [_LNPropertyListDatePickerInnerCell new];
	cell.childCells = @[_datePicker.cell, _timePicker.cell];
	cell.bordered = NO;
	self.cell = cell;
	
	[self addSubview:_datePicker];
	[self addSubview:_timePicker];
	
	[_datePicker setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	[_datePicker setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	[_timePicker setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	[_timePicker setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	[NSLayoutConstraint activateConstraints:@[
											  [self.heightAnchor constraintEqualToAnchor:_datePicker.heightAnchor],
											  [self.leadingAnchor constraintEqualToAnchor:_datePicker.leadingAnchor],
											  [self.centerYAnchor constraintEqualToAnchor:_datePicker.centerYAnchor],
											  [_timePicker.leadingAnchor constraintEqualToAnchor:_datePicker.trailingAnchor constant:2],
											  [self.centerYAnchor constraintEqualToAnchor:_timePicker.centerYAnchor],
											  [self.trailingAnchor constraintEqualToAnchor:_timePicker.trailingAnchor],
											  ]];
	
	[self setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	[self setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
}

- (void)_setDateValue:(NSDate *)dateValue sendAction:(BOOL)sendAction
{
	self.objectValue = dateValue;
	
	_datePicker.dateValue = self.dateValue;
	_timePicker.dateValue = self.dateValue;
	if(LNPropertyListDatePicker.__datePicker.target == self)
	{
		LNPropertyListDatePicker.__datePicker.dateValue = self.dateValue;
	}
	
	if(sendAction)
	{
		[self sendAction:self.action to:self.target];
	}
}

- (NSDate *)dateValue
{
	return self.objectValue;
}

- (void)setDateValue:(NSDate *)dateValue
{
	[self _setDateValue:dateValue sendAction:NO];
}

- (IBAction)_internalDatePickerValueChanged:(id)sender
{
	[self _setDateValue:[sender dateValue] sendAction:YES];
}

@end
