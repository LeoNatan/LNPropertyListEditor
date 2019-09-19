//
//  LNPropertyListDatePicker.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/30/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListDatePicker.h"
#import "_LNPropertyListDatePicker.h"
#import "LNPropertyListDatePickerCell.h"

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

IB_DESIGNABLE
@implementation LNPropertyListDatePicker
{
	_LNPropertyListDatePicker* _datePicker;
	NSDatePicker* _timePicker;
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
	_datePicker.cell = [LNLeadingZerosDatePickerCell new];
	_datePicker.font = font;
	_datePicker.datePickerStyle = NSDatePickerStyleTextField;
	_datePicker.datePickerElements = NSDatePickerElementFlagYearMonthDay | NSDatePickerElementFlagEra;
	_datePicker.bordered = NO;
	_datePicker.drawsBackground = NO;
	_datePicker.translatesAutoresizingMaskIntoConstraints = NO;
	_datePicker.target = self;
	_datePicker.action = @selector(_internalDatePickerValueChanged:);
	
	_timePicker = [NSDatePicker new];
	_timePicker.cell = [LNPropertyListDatePickerCell new];
	_timePicker.font = font;
	_timePicker.datePickerStyle = NSDatePickerStyleTextField;
	_timePicker.datePickerElements = NSDatePickerElementFlagHourMinuteSecond | NSDatePickerElementFlagTimeZone;
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
											  [self.centerYAnchor constraintEqualToAnchor:_datePicker.centerYAnchor constant:-1.5],
											  [_timePicker.leadingAnchor constraintEqualToAnchor:_datePicker.trailingAnchor constant:2],
											  [self.centerYAnchor constraintEqualToAnchor:_timePicker.centerYAnchor constant:-1.5],
											  [self.trailingAnchor constraintEqualToAnchor:_timePicker.trailingAnchor],
											  ]];
	
	[self setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	[self setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	
	self.wantsLayer = YES;
	self.layer.masksToBounds = NO;
}

- (void)_setDateValue:(NSDate *)dateValue sendAction:(BOOL)sendAction
{
	self.objectValue = dateValue;
	
	_datePicker.dateValue = self.dateValue;
	_timePicker.dateValue = self.dateValue;
	_datePicker.visualDatePicker.dateValue = self.dateValue;
	_datePicker.textDatePicker.dateValue = self.dateValue;
	
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

- (BOOL)resignFirstResponder
{
	return [super resignFirstResponder];
}

@end
