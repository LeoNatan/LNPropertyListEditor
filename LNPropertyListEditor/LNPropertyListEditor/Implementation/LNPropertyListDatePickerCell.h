//
//  LNPropertyListDatePickerCell.h
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/29/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSDatePickerCell ()

- (BOOL)_textFieldWithStepperTrackMouse:(id)arg1 inRect:(NSRect)arg2 ofView:(id)arg3 untilMouseUp:(BOOL)arg4;

@end

@interface LNLeadingZerosDatePickerCell : NSDatePickerCell

@property (nonatomic) BOOL drawsBackgroundOnFirstResponder;

@end

@interface LNPropertyListDatePickerCell : LNLeadingZerosDatePickerCell

@end
