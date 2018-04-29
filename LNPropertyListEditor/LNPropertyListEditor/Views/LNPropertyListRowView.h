//
//  LNPropertyListRowView.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/16/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LNPropertyListEditor-Private.h"
#import "LNPropertyListNode.h"

@interface LNPropertyListRowView : NSTableRowView

@property (nonatomic, weak) LNPropertyListEditor* editor;
@property (nonatomic, strong) LNPropertyListNode* node;

- (void)updateEditButtons;

@end
