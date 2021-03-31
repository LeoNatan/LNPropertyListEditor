//
//  LNPropertyListCellView.h
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/12/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LNPropertyListDatePicker.h"

@interface LNPropertyListCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet LNPropertyListDatePicker *datePicker;
@property (nonatomic, strong) IBOutlet NSPopUpButton *typeButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *typeButtonLeadingConstraint;
@property (nonatomic, weak) IBOutlet NSButton *minusButton;
@property (nonatomic, weak) IBOutlet NSButton *plusButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *buttonsConstraint;

@property (nonatomic, readonly) BOOL showsControlButtons;
- (void)setShowsControlButtons:(BOOL)showsControlButtons addButtonEnabled:(BOOL)addButtonEnabled deleteButtonEnabled:(BOOL)deleteButtonEnabled;

- (void)setControlWithString:(NSString*)str setToolTip:(BOOL)setToolTip;
- (void)setControlWithBoolean:(BOOL)boolean;
- (void)setControlWithDate:(NSDate*)date;
- (void)setControlEditable:(BOOL)editable;
- (void)flashError;

@end
