//
//  LNPropertyListEditor.h
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/12/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LNPropertyListEditor.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
	unsigned int delegate_willChangeNode : 1;
	unsigned int delegate_didChangeNode : 1;
	unsigned int delegate_canEditKeyOfNode : 1;
	unsigned int delegate_canEditTypeOfNode : 1;
	unsigned int delegate_canEditValueOfNode : 1;
	unsigned int delegate_canDeleteNode : 1;
	unsigned int delegate_canAddNewNodeInNode : 1;
	unsigned int delegate_canMoveNode : 1;
	unsigned int delegate_canPasteNode : 1;
	unsigned int delegate_canReorderChildrenOfNode : 1;
	unsigned int delegate_defaultPropertyListForAddingInNode : 1;
	
	unsigned int dataTransformer_displayNameForNode : 1;
	unsigned int dataTransformer_transformValueForDisplay : 1;
	unsigned int dataTransformer_transformValueForStorage : 1;
} __LNPropertyListEditor_flags;

@interface LNPropertyListEditor ()

@property (nonatomic) __LNPropertyListEditor_flags flags;
@property (nonatomic, weak) IBOutlet NSOutlineView* outlineView;

/// The current sort descriptors of the underlying outline view.
@property (nullable, nonatomic, copy) NSArray<NSSortDescriptor*>* outlineViewSortDescriptors;

- (BOOL)canInsertAtNode:(LNPropertyListNode*)node;
- (BOOL)canDeleteNode:(LNPropertyListNode*)node;

@end

NS_ASSUME_NONNULL_END
