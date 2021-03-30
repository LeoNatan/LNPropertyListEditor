//
//  _LNPropertyListDatePicker.h
//  LNPropertyListEditor
//
//  Created by Leo Natan on 9/11/19.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LNPropertyListDatePickerPanel;

@interface _LNPropertyListDatePicker : NSDatePicker

@property (nonatomic, strong) NSDatePicker* visualDatePicker;
@property (nonatomic, strong) NSDatePicker* textDatePicker;
@property (nonatomic, strong) LNPropertyListDatePickerPanel* datePickerPanel;

@end
