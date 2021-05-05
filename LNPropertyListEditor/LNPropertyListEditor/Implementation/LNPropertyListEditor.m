//
//  LNPropertyListEditor.m
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/12/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import "LNPropertyListEditor-Private.h"
#import "LNPropertyListNode-Private.h"
#import "LNPropertyListRowView.h"
#import "LNPropertyListCellView.h"

@import ObjectiveC;

@interface LNPropertyListEditor () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate>
{
	IBOutlet NSMenu* _menuItem;
	
	IBOutlet NSTableColumn* _keyColumn;
	IBOutlet NSTableColumn* _typeColumn;
	IBOutlet NSTableColumn* _valueColumn;
	
	NSUndoManager* _undoManager;
}

@end

@implementation LNPropertyListEditor

- (void)prepareForInterfaceBuilder
{
	self.propertyListObject = @{@"Example Text": @"Text", @"Example Number": @123, @"Example Date": NSDate.date, @"Example Boolean": @YES};
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	if(self)
	{
		[self _commonInit];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	
	if(self)
	{
		[self _commonInit];
	}
	
	return self;
}

- (void)_commonInit
{
	NSBundle* bundleToUse;
	
	NSURL* spmBundleURL = [[NSBundle mainBundle] URLForResource:@"LNPropertyListEditor_LNPropertyListEditor" withExtension:@"bundle"];
	if(spmBundleURL != nil)
	{
		bundleToUse = [NSBundle bundleWithURL:spmBundleURL];
	}
	else
	{
		spmBundleURL = [[NSBundle bundleForClass:self.class] URLForResource:@"LNPropertyListEditor_LNPropertyListEditor" withExtension:@"bundle"];
		if(spmBundleURL != nil)
		{
			bundleToUse = [NSBundle bundleWithURL:spmBundleURL];
		}
	}

	if(bundleToUse == nil)
	{
		bundleToUse = [NSBundle bundleForClass:self.class];
	}

	[[[NSNib alloc] initWithNibNamed:@"LNPropertyListEditorOutline" bundle:bundleToUse] instantiateWithOwner:self topLevelObjects:nil];
	
	_outlineView.enclosingScrollView.translatesAutoresizingMaskIntoConstraints = NO;
	_outlineView.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
	
	[_outlineView registerForDraggedTypes:@[LNPropertyListNodePasteboardType]];
	[_outlineView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	
	[_outlineView setTarget:self];
	[_outlineView setAction:@selector(_outlineViewSingleClick)];
	[_outlineView setDoubleAction:@selector(_outlineViewDoubleClick)];
	
	[self addSubview:_outlineView.enclosingScrollView];
	
	[NSLayoutConstraint activateConstraints:@[
											  [self.topAnchor constraintEqualToAnchor:_outlineView.enclosingScrollView.topAnchor],
											  [self.bottomAnchor constraintEqualToAnchor:_outlineView.enclosingScrollView.bottomAnchor],
											  [self.leftAnchor constraintEqualToAnchor:_outlineView.enclosingScrollView.leftAnchor],
											  [self.rightAnchor constraintEqualToAnchor:_outlineView.enclosingScrollView.rightAnchor],
											  ]];
	
	_undoManager = [NSUndoManager new];
	_undoManager.groupsByEvent = NO;
}

- (BOOL)isTypeColumnHidden
{
	return _typeColumn.isHidden;
}

- (void)setTypeColumnHidden:(BOOL)typeColumnHidden
{
	_typeColumn.hidden = typeColumnHidden;
}

- (void)setDelegate:(id<LNPropertyListEditorDelegate>)delegate
{
	_delegate = delegate;
	
	_flags.delegate_willChangeNode = [delegate respondsToSelector:@selector(propertyListEditor:willChangeNode:changeType:previousKey:)];
	_flags.delegate_didChangeNode = [delegate respondsToSelector:@selector(propertyListEditor:didChangeNode:changeType:previousKey:)];
	_flags.delegate_canEditKeyOfNode = [delegate respondsToSelector:@selector(propertyListEditor:canEditKeyOfNode:)];
	_flags.delegate_canEditTypeOfNode = [delegate respondsToSelector:@selector(propertyListEditor:canEditTypeOfNode:)];
	_flags.delegate_canEditValueOfNode = [delegate respondsToSelector:@selector(propertyListEditor:canEditValueOfNode:)];
	_flags.delegate_canDeleteNode = [delegate respondsToSelector:@selector(propertyListEditor:canDeleteNode:)];
	_flags.delegate_canAddNewNodeInNode = [delegate respondsToSelector:@selector(propertyListEditor:canAddChildNodeInNode:)];
	_flags.delegate_canPasteNode = [delegate respondsToSelector:@selector(propertyListEditor:canPasteNode:asChildOfNode:)];
	_flags.delegate_defaultPropertyListForAddingInNode = [delegate respondsToSelector:@selector(propertyListEditor:defaultPropertyListForChildInNode:)];
	_flags.delegate_canMoveNode = [delegate respondsToSelector:@selector(propertyListEditor:canMoveNode:toParentNode:atIndex:)];
	_flags.delegate_canReorderChildrenOfNode = [delegate respondsToSelector:@selector(propertyListEditor:canReorderChildrenOfNode:)];
}

- (void)setDataTransformer:(id<LNPropertyListEditorDataTransformer>)dataTransformer
{
	_dataTransformer = dataTransformer;
	
	_flags.dataTransformer_displayNameForNode = [dataTransformer respondsToSelector:@selector(propertyListEditor:displayNameForNode:)];
	_flags.dataTransformer_transformValueForDisplay = [dataTransformer respondsToSelector:@selector(propertyListEditor:displayValueForNode:)];
	_flags.dataTransformer_transformValueForStorage = [dataTransformer respondsToSelector:@selector(propertyListEditor:storageValueForNode:displayValue:)];
}

- (void)setPropertyListObject:(id)propertyList
{
	_rootPropertyListNode = [[LNPropertyListNode alloc] initWithPropertyListObject:propertyList];
	[self _sortRootNodeIfPossibleWithSortDescriptors:_outlineView.sortDescriptors];
	
	[_outlineView reloadData];
	
	_outlineView.menu = _rootPropertyListNode == nil ? nil : _menuItem;
}

- (id)propertyListObject
{
	return _rootPropertyListNode.propertyListObject;
}

- (void)reloadNode:(LNPropertyListNode*)node reloadChildren:(BOOL)reloadChildren
{
	if(node == self.rootPropertyListNode)
	{
		node = nil;
	}
	
	[_outlineView reloadItem:node reloadChildren:reloadChildren];
}

- (void)expandNode:(LNPropertyListNode *)node expandChildren:(BOOL)expandChildren
{
	if(node == self.rootPropertyListNode)
	{
		node = nil;
	}
	
	[_outlineView expandItem:node expandChildren:expandChildren];
}

- (void)collapseNode:(LNPropertyListNode *)node collapseChildren:(BOOL)collapseChildren
{
	if(node == self.rootPropertyListNode)
	{
		node = nil;
	}
	
	[_outlineView collapseItem:node collapseChildren:collapseChildren];
}

- (IBAction)_dateChanged:(NSDatePicker*)sender
{
	NSUInteger row = [_outlineView rowForView:sender];
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	[self _updateValue:sender.dateValue ofNode:node reloadItem:NO];
}

#pragma mark Node change handling

- (void)_updateKey:(NSString*)key ofNode:(LNPropertyListNode*)node
{
	if([node.key isEqualToString:key])
	{
		return;
	}
	
	NSString* oldKey = node.key;
	node.key = key;
	
	if(_flags.delegate_willChangeNode)
	{
		[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeMove previousKey:oldKey];
	}
	
	[_outlineView reloadItem:node];
	
	[_undoManager beginUndoGrouping];
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _updateKey:oldKey ofNode:node];
	}];
	[_undoManager endUndoGrouping];
	
	if(_flags.delegate_didChangeNode)
	{
		[self.delegate propertyListEditor:self didChangeNode:node changeType:LNPropertyListNodeChangeTypeMove previousKey:oldKey];
	}
}

- (void)_setType:(LNPropertyListNodeType)type children:(id)children value:(id)value forNode:(LNPropertyListNode*)node
{
	LNPropertyListNodeType oldType = node.type;
	id oldValue = node.value;
	id oldChildren = node.children;
	
	node.type = type;
	node.value = value;
	node.children = children;
	
	if(_flags.delegate_willChangeNode)
	{
		[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeUpdate previousKey:node.key];
	}
	
	[_outlineView reloadItem:node reloadChildren:YES];
	
	[_undoManager beginUndoGrouping];
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _setType:oldType children:oldChildren value:oldValue forNode:node];
	}];
	[_undoManager endUndoGrouping];
	
	if(_flags.delegate_didChangeNode)
	{
		[self.delegate propertyListEditor:self didChangeNode:node changeType:LNPropertyListNodeChangeTypeUpdate previousKey:node.key];
	}
}

- (void)_setType:(LNPropertyListNodeType)type children:(id)children value:(id)value forSender:(id)sender
{
	NSInteger row = [self _rowForSender:sender beep:YES];
	if(row == -1)
	{
		return;
	}
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	if(node.type == type)
	{
		return;
	}
	
	[self _setType:type children:children value:value forNode:node];
}

- (void)_convertToType:(LNPropertyListNodeType)newType forSender:(id)sender
{
	[self _setType:newType children:(newType == LNPropertyListNodeTypeArray || newType == LNPropertyListNodeTypeDictionary ? [NSMutableArray new] : nil) value:[LNPropertyListNode defaultValueForType:newType] forSender:sender];
}

- (void)_updateValue:(id)value ofNode:(LNPropertyListNode*)node reloadItem:(BOOL)reloadItem
{
	id valueToUse = nil;
	
	if(_flags.dataTransformer_transformValueForStorage && node.type != LNPropertyListNodeTypeDictionary && node.type != LNPropertyListNodeTypeArray)
	{
		valueToUse = [self.dataTransformer propertyListEditor:self storageValueForNode:node displayValue:value];
	}
	
	if(valueToUse == nil)
	{
		valueToUse = value;
	}
	
	LNPropertyListNodeType typeOfValue = [LNPropertyListNode _typeForObject:valueToUse];
	
	NSAssert(typeOfValue == node.type, @"Value type %@ does not match node type %@.", [LNPropertyListNode stringForType:typeOfValue], [LNPropertyListNode stringForType:node.type]);
	
	if([node.value isEqual:value])
	{
		return;
	}
	
	id oldValue = node.value;
	node.value = valueToUse;
	
	if(_flags.delegate_willChangeNode)
	{
		[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeUpdate previousKey:node.key];
	}
	
	if(reloadItem)
	{
		[_outlineView reloadItem:node];
	}
	
	[_undoManager beginUndoGrouping];
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _updateValue:oldValue ofNode:node reloadItem:YES];
	}];
	[_undoManager endUndoGrouping];
	
	if(_flags.delegate_didChangeNode)
	{
		[self.delegate propertyListEditor:self didChangeNode:node changeType:LNPropertyListNodeChangeTypeUpdate previousKey:node.key];
	}
}

- (void)_insertNode:(LNPropertyListNode*)insertedNode inParentNode:(LNPropertyListNode*)parentNode index:(NSInteger)insertionIndex notifyDelegate:(BOOL)notifyDelegate groupUndoOperation:(BOOL)groupUndo
{
	insertedNode.parent = parentNode;
	
	LNPropertyListNode* parentNodeInOutline = parentNode != _rootPropertyListNode ? parentNode : nil;
	
	if(parentNode.type == LNPropertyListNodeTypeDictionary)
	{
		if(insertedNode.key == nil)
		{
			insertedNode.key = @"New item";
		}
		
		NSUInteger count = 2;
		NSString* originalKey = insertedNode.key;
		
		while([self _nodeContainsChildrenWithKey:insertedNode.key inNode:parentNode excludingNode:insertedNode])
		{
			insertedNode.key = [NSString stringWithFormat:@"%@ - %lu", originalKey, count];
			count += 1;
		}
	}
	
	if(insertionIndex == -1)
	{
		insertionIndex = parentNode.children.count;
	}
	
	[parentNode.children insertObject:insertedNode atIndex:insertionIndex];
	[_outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] inParent:parentNodeInOutline withAnimation:NSTableViewAnimationEffectNone];
	
	if(notifyDelegate && _flags.delegate_willChangeNode)
	{
		[self.delegate propertyListEditor:self willChangeNode:insertedNode changeType:LNPropertyListNodeChangeTypeInsert previousKey:nil];
	}
	
	[_outlineView reloadItem:parentNode];
	if(parentNode.type == LNPropertyListNodeTypeArray)
	{
		[[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertionIndex, parentNode.children.count - insertionIndex)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			[self->_outlineView reloadItem:parentNode.children[idx]];
		}];
	}
	
	[_outlineView endUpdates];
	
	NSInteger insertedRow = [_outlineView rowForItem:insertedNode];
	
	[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:insertedRow] byExtendingSelection:NO];
	
	if(groupUndo)
	{
		[_undoManager beginUndoGrouping];
	}
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _deleteNode:insertedNode notifyDelegate:notifyDelegate groupUndoOperation:groupUndo];
	}];
	if(groupUndo)
	{
		[_undoManager endUndoGrouping];
	}
	
	if(notifyDelegate && _flags.delegate_didChangeNode)
	{
		[self.delegate propertyListEditor:self didChangeNode:insertedNode changeType:LNPropertyListNodeChangeTypeInsert previousKey:nil];
	}
}

- (void)_insertNode:(LNPropertyListNode*)insertedNode sender:(id)sender
{
	NSInteger row = [self _rowForSender:sender beep:NO];
	if(row == -1 && [sender isKindOfClass:[NSNumber class]] == NO)
	{
		row = _rootPropertyListNode.children.count - 1;
	}
	
	[_outlineView beginUpdates];
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	NSUInteger insertionRow;
	
	LNPropertyListNode* parentNode;
	if([_outlineView isItemExpanded:node])
	{
		parentNode = node ?: _rootPropertyListNode;
		insertionRow = 0;
	}
	else
	{
		parentNode = [node parent];
		insertionRow = [parentNode.children indexOfObject:node] + 1;
	}
	
	[self _insertNode:insertedNode inParentNode:parentNode index:insertionRow notifyDelegate:YES groupUndoOperation:YES];
}

- (void)_deleteNode:(LNPropertyListNode*)deletedNode notifyDelegate:(BOOL)notifyDelegate groupUndoOperation:(BOOL)groupUndo
{
	if(deletedNode.parent == nil)
	{
		//Not part of the tree, end the delete operation.
		return;
	}
	
	if([self canDeleteNode:deletedNode] == NO)
	{
		NSBeep();
		return;
	}
	
	NSInteger selectedRow = _outlineView.selectedRow;
	
	[_outlineView beginUpdates];
	
	if(notifyDelegate && _flags.delegate_willChangeNode)
	{
		[self.delegate propertyListEditor:self willChangeNode:deletedNode changeType:LNPropertyListNodeChangeTypeDelete previousKey:deletedNode.key];
	}
	
	LNPropertyListNode* parentNode = deletedNode.parent;
	LNPropertyListNode* parentNodeInOutline = parentNode != _rootPropertyListNode ? deletedNode.parent : nil;
	
	NSUInteger deletionIndex = [deletedNode.parent.children indexOfObject:deletedNode];
	
	[deletedNode.parent.children removeObjectAtIndex:deletionIndex];
	deletedNode.parent = nil;
	[_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:deletionIndex] inParent:parentNodeInOutline withAnimation:NSTableViewAnimationEffectNone];
	
	if(parentNodeInOutline != nil)
	{
		[_outlineView reloadItem:parentNodeInOutline];
	}
	if(deletedNode.parent.type == LNPropertyListNodeTypeArray)
	{
		[[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(deletionIndex, deletedNode.parent.children.count - deletionIndex)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			[self->_outlineView reloadItem:deletedNode.parent.children[idx]];
		}];
	}
	
	[self->_outlineView endUpdates];
	
	if(groupUndo)
	{
		[_undoManager beginUndoGrouping];
	}
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _insertNode:deletedNode inParentNode:parentNode index:deletionIndex notifyDelegate:notifyDelegate groupUndoOperation:groupUndo];
	}];
	if(groupUndo)
	{
		[_undoManager endUndoGrouping];
	}
	
	if(selectedRow != -1)
	{
		if(selectedRow > 0)
		{
			selectedRow -= 1;
		}
		[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
	}
	
	if(notifyDelegate && _flags.delegate_didChangeNode)
	{
		[self.delegate propertyListEditor:self didChangeNode:deletedNode changeType:LNPropertyListNodeChangeTypeDelete previousKey:deletedNode.key];
	}
}

- (void)_deleteNodeWithSender:(id)sender
{
	if([(NSView*)self.window.firstResponder isDescendantOf:self])
	{
		[self.window makeFirstResponder:self.outlineView];
	}
	
	NSInteger row = [self _rowForSender:sender beep:YES];
	if(row == -1)
	{
		return;
	}
	
	LNPropertyListNode* deletedNode = [_outlineView itemAtRow:row];
	
	[self _deleteNode:deletedNode notifyDelegate:YES groupUndoOperation:YES];
}

- (void)_moveNode:(LNPropertyListNode*)node intoParentNode:(LNPropertyListNode*)parentNode index:(NSInteger)parentIndex
{
	if(_flags.delegate_willChangeNode)
	{
		[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeMove previousKey:nil];
	}
	[_undoManager beginUndoGrouping];
	NSInteger indexDelta = 0;
	if(node.parent == parentNode)
	{
		NSInteger beforeIndex = [node.parent.children indexOfObject:node];
		if(beforeIndex < parentIndex)
		{
			indexDelta = -1;
		}
	}
	parentIndex += indexDelta;
	[self _deleteNode:node notifyDelegate:NO groupUndoOperation:NO];
	[self _insertNode:node inParentNode:parentNode index:parentIndex notifyDelegate:NO groupUndoOperation:NO];
	[_undoManager endUndoGrouping];
	if(_flags.delegate_didChangeNode)
	{
		[self.delegate propertyListEditor:self didChangeNode:node changeType:LNPropertyListNodeChangeTypeMove previousKey:nil];
	}
}

#pragma mark Private

- (BOOL)_validateCanAddForSender:(id)sender
{
	if(_flags.delegate_canAddNewNodeInNode)
	{
		NSInteger row = [self _rowForSender:sender beep:NO];
		id node = [self.outlineView itemAtRow:row];
		return [self canInsertAtNode:node];
	}
	
	return YES;
}

- (BOOL)_validateCanPasteForSender:(id)sender
{
	BOOL canPaste = [NSPasteboard.generalPasteboard canReadItemWithDataConformingToTypes:@[LNPropertyListNodePasteboardType, LNPropertyListNodeXcodeKeyType]];
	NSInteger row = [self _rowForSender:sender beep:NO];
	id node = [self.outlineView itemAtRow:row] ?: self.rootPropertyListNode;
	if(canPaste && _flags.delegate_canAddNewNodeInNode)
	{
		canPaste = [self canInsertAtNode:node];
	}
	if(canPaste && _flags.delegate_canPasteNode)
	{
		LNPropertyListNode* pasted = [LNPropertyListNode _nodeFromPasteboard:NSPasteboard.generalPasteboard];
		canPaste = [self.delegate propertyListEditor:self canPasteNode:pasted asChildOfNode:node];
	}
	return canPaste;
}

- (BOOL)_validateCanDeleteForSender:(id)sender
{
	if(_flags.delegate_canDeleteNode)
	{
		NSInteger row = [self _rowForSender:sender beep:NO];
		id node = [self.outlineView itemAtRow:row];
		return node != nil && [self canDeleteNode:node];
	}
	
	return YES;
}

- (BOOL)canInsertAtNode:(LNPropertyListNode*)node
{
	if(_flags.delegate_canAddNewNodeInNode)
	{
		LNPropertyListNode* nodeToAddIn = node.parent;
		if([_outlineView isItemExpanded:node])
		{
			nodeToAddIn = node;
		}
		
		if(nodeToAddIn == nil)
		{
			nodeToAddIn = self.rootPropertyListNode;
		}
		
		return [self.delegate propertyListEditor:self canAddChildNodeInNode:nodeToAddIn];
	}
	
	return YES;
}

- (BOOL)canPaste:(LNPropertyListNode*)pasted atNode:(LNPropertyListNode*)node
{
	if(_flags.delegate_canPasteNode)
	{
		LNPropertyListNode* nodeToAddIn = node.parent;
		if([_outlineView isItemExpanded:node])
		{
			nodeToAddIn = node;
		}
		
		if(nodeToAddIn == nil)
		{
			nodeToAddIn = self.rootPropertyListNode;
		}
		
		return [self.delegate propertyListEditor:self canPasteNode:pasted asChildOfNode:nodeToAddIn];
	}
	
	return YES;
}

- (BOOL)canDeleteNode:(LNPropertyListNode*)node
{
	if(_flags.delegate_canDeleteNode)
	{
		return [self.delegate propertyListEditor:self canDeleteNode:node];
	}
	
	return YES;
}

- (NSDragOperation)canDragNode:(LNPropertyListNode*)dragged toParentNode:(LNPropertyListNode*)parentNode atIndex:(NSInteger)index wantsCopy:(BOOL)wantsCopy
{
	NSDragOperation expectedOperation = wantsCopy ? NSDragOperationCopy : NSDragOperationMove;
	
	if(dragged.parent == nil)
	{
		BOOL canInsert = _flags.delegate_canAddNewNodeInNode ? [self.delegate propertyListEditor:self canAddChildNodeInNode:parentNode] : YES;
		
		//Dragged from outside
		return canInsert ? NSDragOperationCopy : NSDragOperationNone;
	}
	
	if(wantsCopy == NO && _flags.delegate_canMoveNode)
	{
		if([self.delegate propertyListEditor:self canMoveNode:dragged toParentNode:parentNode atIndex:index])
		{
			return NSDragOperationMove;
		}
	}
	
	BOOL canDelete = YES;
	BOOL canInsert = YES;
	
	if(wantsCopy == NO && _flags.delegate_canDeleteNode)
	{
		canDelete = [self.delegate propertyListEditor:self canDeleteNode:dragged];
	}
	
	if(_flags.delegate_canAddNewNodeInNode)
	{
		canInsert = [self.delegate propertyListEditor:self canAddChildNodeInNode:dragged];
	}
	
	if(canInsert && canDelete)
	{
		return expectedOperation;
	}
	else if(canInsert && !canDelete)
	{
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

#pragma mark Outlets

- (NSInteger)_rowForSender:(id)sender beep:(BOOL)beep
{
	NSInteger row = -1;
	
	if([sender isKindOfClass:[NSMenuItem class]])
	{
		NSPopUpButton* button = objc_getAssociatedObject([sender menu], "button");
		row = [_outlineView rowForView:button];
	}
	if(row == -1 && [sender isKindOfClass:[NSView class]])
	{
		row = [_outlineView rowForView:sender];
	}
	if(row == -1)
	{
		row = _outlineView.clickedRow;
	}
	if(row == -1)
	{
		row = _outlineView.selectedRow;
	}
	
	if(row == -1 && beep == YES)
	{
		NSBeep();
	}
	return row;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(undo:))
	{
		return _undoManager.canUndo;
	}
	
	if(menuItem.action == @selector(redo:))
	{
		return _undoManager.canRedo;
	}
	
	if(menuItem.action == @selector(add:))
	{
		return [self _validateCanAddForSender:menuItem];
	}
	
	BOOL extraCase = YES;
	if(menuItem.action == @selector(delete:))
	{
		extraCase = [self _validateCanDeleteForSender:menuItem];
	}
	
	if(menuItem.action == @selector(cut:))
	{
		extraCase = [self _validateCanDeleteForSender:menuItem];
	}
	
	if((menuItem.action == @selector(boolean:) ||
		menuItem.action == @selector(number:) ||
		menuItem.action == @selector(string:) ||
		menuItem.action == @selector(data:) ||
		menuItem.action == @selector(date:) ||
		menuItem.action == @selector(array:) ||
		menuItem.action == @selector(dictionary:)) &&
	   _flags.delegate_canEditTypeOfNode)
	{
		NSInteger row = [self _rowForSender:menuItem beep:NO];
		id node = [self.outlineView itemAtRow:row];
		extraCase = node != nil && [self.delegate propertyListEditor:self canEditTypeOfNode:node];
	}
	
	if(menuItem.action == @selector(paste:))
	{
		return [self _validateCanPasteForSender:menuItem];
	}
	
	return extraCase && (menuItem.action && [self respondsToSelector:menuItem.action] && ([self _rowForSender:menuItem beep:NO] != -1 || menuItem.action == @selector(add:)));
}

- (BOOL)_nodeContainsChildrenWithKey:(NSString*)key inNode:(LNPropertyListNode*)node excludingNode:(LNPropertyListNode*)excludedNode
{
	return [node.children filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key == %@ && self != %@", key, excludedNode]].count > 0;
}

- (id)_defaultPropertyListForSender:(id)sender
{
	id insertedPropertyListObject = nil;

	if(_flags.delegate_defaultPropertyListForAddingInNode)
	{
		LNPropertyListNode* node = [_outlineView itemAtRow:[self _rowForSender:sender beep:NO]];
		LNPropertyListNode* nodeToAddIn = node.parent;
		if([_outlineView isItemExpanded:node])
		{
			nodeToAddIn = node;
		}
		
		if(nodeToAddIn == nil)
		{
			nodeToAddIn = self.rootPropertyListNode;
		}
		
		insertedPropertyListObject = [self.delegate propertyListEditor:self defaultPropertyListForChildInNode:nodeToAddIn];
	}
	
	if(insertedPropertyListObject == nil)
	{
		insertedPropertyListObject = @"";
	}
	
	return insertedPropertyListObject;
}

- (IBAction)add:(id)sender
{
	if([self _validateCanAddForSender:sender] == NO)
	{
		NSBeep();
		return;
	}
	
	LNPropertyListNode* insertedNode;
	id insertedPropertyList = [self _defaultPropertyListForSender:sender];
	if([insertedPropertyList isKindOfClass:LNPropertyListNode.class])
	{
		insertedNode = insertedPropertyList;
	}
	else
	{
		insertedNode = [[LNPropertyListNode alloc] initWithPropertyListObject:insertedPropertyList];
	}
	
	[self _insertNode:insertedNode sender:sender];
}

- (IBAction)cut:(id)sender
{
	[self copy:sender];
	[self delete:sender];
}

- (IBAction)copy:(id)sender
{
	if([(NSView*)self.window.firstResponder isDescendantOf:self])
	{
		[self.window makeFirstResponder:self.outlineView];
	}
	
	NSInteger row = [self _rowForSender:sender beep:YES];
	if(row == -1)
	{
		return;
	}
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	id<NSPasteboardWriting> pbWriter = node.pasteboardWriter;
	
	[NSPasteboard.generalPasteboard clearContents];
	for (NSPasteboardType type in [pbWriter writableTypesForPasteboard:NSPasteboard.generalPasteboard])
	{
		[NSPasteboard.generalPasteboard setData:[node.pasteboardWriter pasteboardPropertyListForType:type] forType:type];
	}
	
	[LNPropertyListNode _clearPasteboardMapping];
}

- (IBAction)paste:(id)sender
{
	if([self _validateCanPasteForSender:sender] == NO)
	{
		NSBeep();
		return;
	}
	
	LNPropertyListNode* node = [LNPropertyListNode _nodeFromPasteboard:NSPasteboard.generalPasteboard];
	
	[self _insertNode:node sender:sender];
}

- (IBAction)delete:(id)sender
{
	[self _deleteNodeWithSender:sender];
}

- (IBAction)boolean:(id)sender
{
	[self _convertToType:LNPropertyListNodeTypeBoolean forSender:sender];
}

- (IBAction)number:(id)sender
{
	[self _convertToType:LNPropertyListNodeTypeNumber forSender:sender];
}

- (IBAction)string:(id)sender
{
	[self _convertToType:LNPropertyListNodeTypeString forSender:sender];
}

- (IBAction)date:(id)sender
{
	[self _convertToType:LNPropertyListNodeTypeDate forSender:sender];
}

- (IBAction)data:(id)sender
{
	[self _convertToType:LNPropertyListNodeTypeData forSender:sender];
}

- (IBAction)array:(id)sender
{
	[self _convertToType:LNPropertyListNodeTypeArray forSender:sender];
}

- (IBAction)dictionary:(id)sender
{
	[self _convertToType:LNPropertyListNodeTypeDictionary forSender:sender];
}

- (IBAction)_setToBoolValue:(id)sender
{
	NSInteger row = [self _rowForSender:sender beep:YES];
	if(row == -1)
	{
		return;
	}
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	[self _updateValue:[NSNumber numberWithBool:[[sender menu].itemArray indexOfObject:sender] == 1] ofNode:node reloadItem:YES];
}

- (IBAction)undo:(id)sender
{
	[_undoManager undo];
}

- (IBAction)redo:(id)sender
{
	[_undoManager redo];
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(LNPropertyListNode*)item
{
	if(item == nil)
	{
		return _rootPropertyListNode == nil ? 0 : _rootPropertyListNode.type == LNPropertyListNodeTypeArray || _rootPropertyListNode.type == LNPropertyListNodeTypeDictionary ? _rootPropertyListNode.children.count : 1;
	}
	
	return item.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(LNPropertyListNode*)item
{
	if(item == nil)
	{
		item = _rootPropertyListNode;
	}
	
	return [item.children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(LNPropertyListNode*)item
{
	return item.type == LNPropertyListNodeTypeArray || item.type == LNPropertyListNodeTypeDictionary;
}

- (void)_outlineViewSingleClick
{
	LNPropertyListNode* node = [_outlineView itemAtRow:_outlineView.clickedRow];
	
	if(node == nil)
	{
		return;
	}
	
	if(node.type == LNPropertyListNodeTypeDate)
	{
		LNPropertyListCellView* view = [_outlineView viewAtColumn:_outlineView.clickedColumn row:_outlineView.clickedRow makeIfNecessary:NO];
		[self.window makeFirstResponder:view.datePicker];
	}
}

- (void)_outlineViewDoubleClick
{
	LNPropertyListNode* node = [_outlineView itemAtRow:_outlineView.clickedRow];
	
	if(node == nil)
	{
		return;
	}
	
	if(node.type == LNPropertyListNodeTypeDate)
	{
		return;
	}
	
	[_outlineView editColumn:_outlineView.clickedColumn row:_outlineView.clickedRow withEvent:NSApp.currentEvent select:YES];
}

#pragma mark NSOutlineViewDelegate

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	LNPropertyListRowView* rowView = [LNPropertyListRowView new];
	rowView.editor = self;
	rowView.node = item;
	
	return rowView;
}

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(LNPropertyListNode*)item
{
	LNPropertyListCellView* cellView;
	NSString* identifier;
	NSString* value;
	BOOL editable = NO;
	
	if(tableColumn == _keyColumn)
	{
		identifier = @"KeyCell";
		value = [LNPropertyListNode stringKeyOfNode:item];
		
		BOOL transformed = NO;
		if(self.dataTransformer && _flags.dataTransformer_displayNameForNode)
		{
			NSString* displayName = [self.dataTransformer propertyListEditor:self displayNameForNode:item];
			if(displayName != nil && [displayName isEqualToString:value] == NO)
			{
				value = displayName;
				transformed = YES;
			}
		}
		
		editable = transformed == NO && (item.parent == nil || item.parent.type == LNPropertyListNodeTypeDictionary);
		if(editable && _flags.delegate_canEditKeyOfNode)
		{
			editable = [self.delegate propertyListEditor:self canEditKeyOfNode:item];
		}
	}
	else if(tableColumn == _typeColumn)
	{
		identifier = @"TypeCell";
		editable = YES;
		
		if(_flags.dataTransformer_transformValueForDisplay && item.type != LNPropertyListNodeTypeArray && item.type != LNPropertyListNodeTypeDictionary)
		{
			item._cachedDisplayValue = [self.dataTransformer propertyListEditor:self displayValueForNode:item];
			value = [LNPropertyListNode stringForType:[LNPropertyListNode _typeForObject:item._cachedDisplayValue]];
		}
		
		if(value == nil)
		{
			item._cachedDisplayValue = nil;
			value = [LNPropertyListNode stringForType:item.type];
		}
		
		if(editable && _flags.delegate_canEditTypeOfNode)
		{
			editable = [self.delegate propertyListEditor:self canEditTypeOfNode:item];
		}
	}
	else if(tableColumn == _valueColumn)
	{
		LNPropertyListNodeType type = item._cachedDisplayValue ? [LNPropertyListNode _typeForObject:item._cachedDisplayValue] : item.type;
		
		if(type == LNPropertyListNodeTypeBoolean)
		{
			identifier = @"BoolCell";
		}
		else if(type == LNPropertyListNodeTypeDate)
		{
			identifier = @"DateCell";
		}
		else
		{
			identifier = @"ValueCell";
		}
		
		editable = !(type == LNPropertyListNodeTypeArray || type == LNPropertyListNodeTypeDictionary);
		value = [LNPropertyListNode stringValueOfNode:item];
		
		if(editable && _flags.delegate_canEditValueOfNode)
		{
			editable = [self.delegate propertyListEditor:self canEditValueOfNode:item];
		}
	}
	
	cellView = [outlineView makeViewWithIdentifier:identifier owner:self];
	if([cellView.identifier isEqualToString:@"BoolCell"])
	{
		[cellView setControlWithBoolean:[item.value boolValue]];
	}
	else if([cellView.identifier isEqualToString:@"DateCell"])
	{
		[cellView setControlWithDate:item.value];
	}
	else
	{
		[cellView setControlWithString:value setToolTip:(tableColumn == _keyColumn || (tableColumn == _valueColumn && editable))];
	}
	
	[cellView setControlEditable:editable];
	
	cellView.textField.delegate = self;
	
	return cellView;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	id item = notification.userInfo[@"NSObject"];
	[[self.outlineView rowViewAtRow:[self.outlineView rowForItem:item] makeIfNecessary:NO] updateEditButtons];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	id item = notification.userInfo[@"NSObject"];
	[[self.outlineView rowViewAtRow:[self.outlineView rowForItem:item] makeIfNecessary:NO] updateEditButtons];
}

- (void)_sortRootNodeIfPossibleWithSortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
{
	[self.rootPropertyListNode _sortUsingDescriptors:sortDescriptors validator:^BOOL(LNPropertyListNode* node) {
		if(!_flags.delegate_canReorderChildrenOfNode)
		{
			return YES;
		}
		
		return [self.delegate propertyListEditor:self canReorderChildrenOfNode:node];
	} callback:^(LNPropertyListNode* node, BOOL will) {
		if(will && _flags.delegate_willChangeNode)
		{
			[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeReorderChildren previousKey:nil];
		}
		
		if(!will && _flags.delegate_didChangeNode)
		{
			[self.delegate propertyListEditor:self didChangeNode:node changeType:LNPropertyListNodeChangeTypeReorderChildren previousKey:nil];
		}
	}];
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors;
{
	//Make the outline view as the first responder to prevent issues with currently edited text fields.
	[outlineView.window makeFirstResponder:outlineView];
	
	LNPropertyListNode* node = [outlineView itemAtRow:outlineView.selectedRow];
	[self _sortRootNodeIfPossibleWithSortDescriptors:outlineView.sortDescriptors];
	[self.outlineView reloadItem:nil reloadChildren:YES];
	
	NSInteger selectionRow = [self.outlineView rowForItem:node];
	[self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectionRow] byExtendingSelection:NO];
	[self.outlineView scrollRowToVisible:selectionRow];
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification
{
    [_outlineView sizeLastColumnToFit];
}

- (id<NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(LNPropertyListNode*)item
{
	NSParameterAssert([item isKindOfClass:LNPropertyListNode.class]);
	
	return [item pasteboardWriter];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(LNPropertyListNode*)item proposedChildIndex:(NSInteger)index
{
	item = item ?: _rootPropertyListNode;
	NSParameterAssert([item isKindOfClass:LNPropertyListNode.class]);
	if(item.type != LNPropertyListNodeTypeArray && item.type != LNPropertyListNodeTypeDictionary)
	{
		return NSDragOperationNone;
	}
	
	if(index == -1)
	{
		index = item.children.count;
	}
	
	__block NSDragOperation rv = NSDragOperationNone;
	
	[info enumerateDraggingItemsWithOptions:0 forView:nil classes:@[LNPropertyListNode.class] searchOptions:@{} usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
		rv = [self canDragNode:draggingItem.item toParentNode:item ?: _rootPropertyListNode atIndex:index wantsCopy:info.draggingSourceOperationMask == NSDragOperationCopy];
	}];
	
	return rv;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(LNPropertyListNode*)item childIndex:(NSInteger)index
{
	item = item ?: _rootPropertyListNode;
	NSParameterAssert([item isKindOfClass:LNPropertyListNode.class]);
	if(item.type != LNPropertyListNodeTypeArray && item.type != LNPropertyListNodeTypeDictionary)
	{
		return NO;
	}
	
	if(index == -1)
	{
		index = item.children.count;
	}
	
	[info enumerateDraggingItemsWithOptions:0 forView:nil classes:@[LNPropertyListNode.class] searchOptions:@{} usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
		LNPropertyListNode* draggedItem = draggingItem.item;
		if(draggedItem.parent == item && [item.children indexOfObject:draggedItem] == index)
		{
			return;
		}
		
		if(info.draggingSourceOperationMask == NSDragOperationCopy)
		{
			[self _insertNode:draggedItem.copy inParentNode:item index:index notifyDelegate:YES groupUndoOperation:YES];
		}
		else
		{
			[self _moveNode:draggedItem intoParentNode:item index:index];
		}
	}];
	
	return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	[LNPropertyListNode _clearPasteboardMapping];
}

#pragma mark NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)note
{
	NSTextField *textField = note.object;
	NSUInteger row = [_outlineView rowForView:textField];
	NSUInteger column = [_outlineView columnForView:textField];
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	if(column == 0)
	{
		if([self _nodeContainsChildrenWithKey:textField.stringValue inNode:node.parent excludingNode:node] == NO)
		{
			[self _updateKey:textField.stringValue ofNode:node];
		}
		else
		{
			NSAlert* alert = [NSAlert new];
			alert.alertStyle = NSAlertStyleWarning;
			alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"The key “%@” already exists in containing item.", @""), textField.stringValue];
			[alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
			
			textField.stringValue = node.key;
			
			[(LNPropertyListCellView*)textField.superview flashError];
			
			[alert runModal];
		}
	}
	else if(column == 2)
	{
		id newValue = [LNPropertyListNode convertString:textField.stringValue toObjectOfType:node.type];
		if(newValue != nil)
		{
			[self _updateValue:newValue ofNode:node reloadItem:YES];
		}
		else
		{
			textField.stringValue = [LNPropertyListNode stringValueOfNode:node];
			[(LNPropertyListCellView*)textField.superview flashError];
		}
	}
}

@end
