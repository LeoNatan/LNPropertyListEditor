//
//  _LNPropertyListDatePicker.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 9/11/19.
//  Copyright © 2019 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LNPropertyListDatePickerPanel;

@interface _LNPropertyListDatePicker : NSDatePicker

@property (nonatomic, strong) NSDatePicker* visualDatePicker;
@property (nonatomic, strong) NSDatePicker* textDatePicker;
@property (nonatomic, strong) LNPropertyListDatePickerPanel* datePickerPanel;

@end
