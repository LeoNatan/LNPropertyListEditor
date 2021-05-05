//
//  LNPropertyListDatePicker.m
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/30/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
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
}

- (void)prepareForInterfaceBuilder
{
	_datePicker.dateValue = [NSDate date];
}

- (void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	
	[_datePicker setEnabled:enabled];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSFont* font = [NSFont monospacedDigitSystemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightRegular];
	
	_datePicker = [_LNPropertyListDatePicker new];
	_datePicker.cell = [LNPropertyListDatePickerCell new];
	_datePicker.font = font;
	_datePicker.datePickerStyle = NSDatePickerStyleTextField;
	_datePicker.datePickerElements = NSDatePickerElementFlagYearMonthDay | NSDatePickerElementFlagEra | NSDatePickerElementFlagHourMinuteSecond | NSDatePickerElementFlagTimeZone;
	_datePicker.bordered = NO;
	_datePicker.drawsBackground = NO;
	_datePicker.translatesAutoresizingMaskIntoConstraints = NO;
	_datePicker.target = self;
	_datePicker.action = @selector(_internalDatePickerValueChanged:);
	
	_LNPropertyListDatePickerInnerCell* cell = [_LNPropertyListDatePickerInnerCell new];
	cell.childCells = @[_datePicker.cell];
	cell.bordered = NO;
	self.cell = cell;
	
	[self addSubview:_datePicker];
	
	[_datePicker setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	[_datePicker setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
	[NSLayoutConstraint activateConstraints:@[
											  [self.heightAnchor constraintEqualToAnchor:_datePicker.heightAnchor],
											  [self.leadingAnchor constraintEqualToAnchor:_datePicker.leadingAnchor],
											  [self.centerYAnchor constraintEqualToAnchor:_datePicker.centerYAnchor constant:-1.5],
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
