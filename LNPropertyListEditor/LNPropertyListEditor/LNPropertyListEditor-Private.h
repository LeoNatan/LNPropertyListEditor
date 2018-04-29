//
//  LNPropertyListEditor.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LNPropertyListEditor.h"

typedef struct {
	unsigned int delegate_willChangeNode : 1;
	unsigned int delegate_canEditKeyOfNode : 1;
	unsigned int delegate_canEditTypeOfNode : 1;
	unsigned int delegate_canEditValueOfNode : 1;
	unsigned int delegate_canDeleteNode : 1;
	unsigned int delegate_canAddNewNodeInNode : 1;
	unsigned int delegate_canPasteNode : 1;
	unsigned int delegate_defaultPropertyListForAddingInNode : 1;
	
	unsigned int dataTransformer_displayNameForNode : 1;
	unsigned int dataTransformer_transformValueForDisplay : 1;
	unsigned int dataTransformer_transformValueForStorage : 1;
} __LNPropertyListEditor_flags;

@interface LNPropertyListEditor ()

@property (nonatomic) __LNPropertyListEditor_flags flags;
@property (nonatomic, weak) IBOutlet NSOutlineView* outlineView;

- (BOOL)canInsertAtNode:(LNPropertyListNode*)node;
- (BOOL)canDeleteNode:(LNPropertyListNode*)node;

@end
