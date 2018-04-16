//
//  LNPropertyListEditor.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LNPropertyListEditor/LNPropertyListNode.h>

IB_DESIGNABLE
@interface LNPropertyListEditor : NSView

- (IBAction)addItem:(id)sender;
- (IBAction)deleteItem:(id)sender;

@property (nonatomic, copy) id propertyList;
@property (nonatomic, readonly) LNPropertyListNode* propertyListNode;

@end
