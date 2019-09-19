//
//  LNPropertyListDatePickerCell.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/29/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSDatePickerCell ()

- (BOOL)_textFieldWithStepperTrackMouse:(id)arg1 inRect:(NSRect)arg2 ofView:(id)arg3 untilMouseUp:(BOOL)arg4;

@end

@interface LNLeadingZerosDatePickerCell : NSDatePickerCell

@end

@interface LNPropertyListDatePickerCell : LNLeadingZerosDatePickerCell

@end
