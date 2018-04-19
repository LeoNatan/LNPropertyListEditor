//
//  LNPropertyListCellView.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LNPropertyListCellView : NSTableCellView

@property (nonatomic, strong) IBOutlet NSPopUpButton *typeButton;
@property (nonatomic, weak) IBOutlet NSButton *minusButton;
@property (nonatomic, weak) IBOutlet NSButton *plusButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *buttonsConstraint;

@property (nonatomic) BOOL showsControlButtons;

- (void)setControlWithString:(NSString*)str setToolTip:(BOOL)setToolTip;
- (void)setControlWithBoolean:(BOOL)boolean;
- (void)flashError;

@end
