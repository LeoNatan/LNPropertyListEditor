//
//  LNPropertyListEditor.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListEditor-Private.h"
#import "LNPropertyListNode-Private.h"
#import "LNPropertyListRowView.h"
#import "LNPropertyListCellView.h"

@import ObjectiveC;

static NSPasteboardType LNPropertyListNodePasteboardType = @"com.LeoNatan.LNPropertyListNode";

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
	self.propertyList = @{@"Example Text": @"Text", @"Example Number": @123, @"Example Date": NSDate.date};
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
	[[[NSNib alloc] initWithNibNamed:@"LNPropertyListEditorOutline" bundle:[NSBundle bundleForClass:self.class]] instantiateWithOwner:self topLevelObjects:nil];
	
	_outlineView.enclosingScrollView.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self addSubview:_outlineView.enclosingScrollView];
	
	[NSLayoutConstraint activateConstraints:@[
											  [self.topAnchor constraintEqualToAnchor:_outlineView.enclosingScrollView.topAnchor],
											  [self.bottomAnchor constraintEqualToAnchor:_outlineView.enclosingScrollView.bottomAnchor],
											  [self.leftAnchor constraintEqualToAnchor:_outlineView.enclosingScrollView.leftAnchor],
											  [self.rightAnchor constraintEqualToAnchor:_outlineView.enclosingScrollView.rightAnchor],
											  ]];
	
	_undoManager = [NSUndoManager new];
}

- (BOOL)isTypeColumnHidden
{
	return _typeColumn.isHidden;
}

- (void)setTypeColumnHidden:(BOOL)typeColumnHidden
{
	_typeColumn.hidden = typeColumnHidden;
}

- (void)layout
{
	[super layout];

	[_outlineView sizeLastColumnToFit];
}

- (void)setDelegate:(id<LNPropertyListEditorDelegate>)delegate
{
	_delegate = delegate;
	
	_flags.delegate_willChangeNode = [delegate respondsToSelector:@selector(propertyListEditor:willChangeNode:changeType:previousKey:)];
	_flags.delegate_canEditKeyOfNode = [delegate respondsToSelector:@selector(propertyListEditor:canEditKeyOfNode:)];
	_flags.delegate_canEditTypeOfNode = [delegate respondsToSelector:@selector(propertyListEditor:canEditTypeOfNode:)];
	_flags.delegate_canEditValueOfNode = [delegate respondsToSelector:@selector(propertyListEditor:canEditValueOfNode:)];
	_flags.delegate_canDeleteNode = [delegate respondsToSelector:@selector(propertyListEditor:canDeleteNode:)];
	_flags.delegate_canAddNewNodeInNode = [delegate respondsToSelector:@selector(propertyListEditor:canAddNewNodeInNode:)];
	_flags.delegate_canPasteNode = [delegate respondsToSelector:@selector(propertyListEditor:canPasteNode:inNode:)];
	_flags.delegate_defaultPropertyListForAddingInNode = [delegate respondsToSelector:@selector(propertyListEditor:defaultPropertyListForAddingInNode:)];
}

- (void)setDataTransformer:(id<LNPropertyListEditorDataTransformer>)dataTransformer
{
	_dataTransformer = dataTransformer;
	
	_flags.dataTransformer_displayNameForNode = [dataTransformer respondsToSelector:@selector(propertyListEditor:displayNameForNode:)];
	_flags.dataTransformer_transformValueForDisplay = [dataTransformer respondsToSelector:@selector(propertyListEditor:transformValueForDisplay:)];
	_flags.dataTransformer_transformValueForStorage = [dataTransformer respondsToSelector:@selector(propertyListEditor:transformValueForStorage:displayValue:)];
}

- (void)setPropertyList:(id)propertyList
{
	_rootPropertyListNode = [[LNPropertyListNode alloc] initWithPropertyList:propertyList];
	
	[_outlineView reloadData];
	
	_outlineView.menu = _rootPropertyListNode == nil ? nil : _menuItem;
}

- (id)propertyList
{
	return _rootPropertyListNode.propertyList;
}

- (void)reloadNode:(LNPropertyListNode*)node reloadChildren:(BOOL)reloadChildren
{
	[_outlineView reloadItem:node reloadChildren:reloadChildren];
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
	
	LNPropertyListCellView* cellView = [[_outlineView rowViewAtRow:[_outlineView rowForItem:node] makeIfNecessary:NO] viewAtColumn:0];
	[cellView setControlWithString:key setToolTip:YES];
	
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _updateKey:oldKey ofNode:node];
	}];
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
	
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _setType:oldType children:oldChildren value:oldValue forSender:@(row)];
	}];
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
		valueToUse = [self.dataTransformer propertyListEditor:self transformValueForStorage:node displayValue:value];
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
	
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _updateValue:oldValue ofNode:node reloadItem:YES];
	}];
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
	LNPropertyListNode* parentNodeInOutline = parentNode != _rootPropertyListNode ? parentNode : nil;
	
	insertedNode.parent = parentNode;
	
	if(parentNode.type == LNPropertyListNodeTypeDictionary)
	{
		if(insertedNode.key == nil)
		{
			insertedNode.key = @"Key";
		}
		
		NSUInteger count = 2;
		NSString* originalKey = insertedNode.key;
		
		while([self _nodeContainsChildrenWithKey:insertedNode.key inNode:parentNode excludingNode:insertedNode])
		{
			insertedNode.key = [NSString stringWithFormat:@"%@ %lu", originalKey, count];
			count += 1;
		}
	}
	
	[parentNode.children insertObject:insertedNode atIndex:insertionRow];
	[_outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionRow] inParent:parentNodeInOutline withAnimation:NSTableViewAnimationEffectNone];
	
	if(_flags.delegate_willChangeNode)
	{
		[self.delegate propertyListEditor:self willChangeNode:insertedNode changeType:LNPropertyListNodeChangeTypeInsert previousKey:nil];
	}
	
	[_outlineView reloadItem:parentNode];
	if(parentNode.type == LNPropertyListNodeTypeArray)
	{
		[[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertionRow, parentNode.children.count - insertionRow)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			[self->_outlineView reloadItem:parentNode.children[idx]];
		}];
	}
	
	[_outlineView endUpdates];
	
	NSInteger insertedRow = [_outlineView rowForItem:insertedNode];
	
	[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:insertedRow] byExtendingSelection:NO];
	
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target delete:@(insertedRow)];
	}];
}

- (void)_deleteNodeWithSender:(id)sender
{
	NSInteger selectedRow = _outlineView.selectedRow;
	
	NSInteger row = [self _rowForSender:sender beep:YES];
	if(row == -1)
	{
		return;
	}
	
	if([self _validateCanDeleteForSender:sender] == NO)
	{
		NSBeep();
		return;
	}
	
	[_outlineView beginUpdates];
	
	LNPropertyListNode* deletedNode = [_outlineView itemAtRow:row];
	
	if(_flags.delegate_willChangeNode)
	{
		[self.delegate propertyListEditor:self willChangeNode:deletedNode changeType:LNPropertyListNodeChangeTypeDelete previousKey:deletedNode.key];
	}
	
	LNPropertyListNode* parentNodeInOutline = deletedNode.parent != _rootPropertyListNode ? deletedNode.parent : nil;
	
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
	
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _insertNode:deletedNode sender:@(row - 1)];
	}];
	
	if(selectedRow != -1)
	{
		if(selectedRow > 0)
		{
			selectedRow -= 1;
		}
		[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
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
	BOOL canPaste = [NSPasteboard.generalPasteboard canReadItemWithDataConformingToTypes:@[LNPropertyListNodePasteboardType]];
	NSInteger row = [self _rowForSender:sender beep:NO];
	id node = [self.outlineView itemAtRow:row] ?: self.rootPropertyListNode;
	if(canPaste && _flags.delegate_canAddNewNodeInNode)
	{
		canPaste = [self canInsertAtNode:node];
	}
	if(canPaste && _flags.delegate_canPasteNode)
	{
		LNPropertyListNode* pasted = [NSKeyedUnarchiver unarchiveObjectWithData:[NSPasteboard.generalPasteboard dataForType:LNPropertyListNodePasteboardType]];
		canPaste = [self.delegate propertyListEditor:self canPasteNode:pasted inNode:node];
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
		
		return [self.delegate propertyListEditor:self canAddNewNodeInNode:nodeToAddIn];
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
		
		return [self.delegate propertyListEditor:self canPasteNode:pasted inNode:nodeToAddIn];
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

#pragma mark Outlets

- (NSInteger)_rowForSender:(id)sender beep:(BOOL)beep
{
	if([sender isKindOfClass:[NSNumber class]])
	{
		return [sender integerValue];
	}
	
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
		
		insertedPropertyListObject = [self.delegate propertyListEditor:self defaultPropertyListForAddingInNode:nodeToAddIn];
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
		insertedNode = [[LNPropertyListNode alloc] initWithPropertyList:insertedPropertyList];
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
	NSInteger row = [self _rowForSender:sender beep:YES];
	if(row == -1)
	{
		return;
	}
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	[NSPasteboard.generalPasteboard clearContents];
	[NSPasteboard.generalPasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:node] forType:LNPropertyListNodePasteboardType];
}

- (IBAction)paste:(id)sender
{
	if([self _validateCanPasteForSender:sender] == NO)
	{
		NSBeep();
		return;
	}
	
	LNPropertyListNode* node = [NSKeyedUnarchiver unarchiveObjectWithData:[NSPasteboard.generalPasteboard dataForType:LNPropertyListNodePasteboardType]];
	
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
			item._cachedDisplayValue = [self.dataTransformer propertyListEditor:self transformValueForDisplay:item];
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

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors;
{
	//Make the outline view as the first responder to prevent issues with currently edited text fields.
	[outlineView.window makeFirstResponder:outlineView];
	
	LNPropertyListNode* node = [outlineView itemAtRow:outlineView.selectedRow];
	[self.rootPropertyListNode _sortUsingDescriptors:outlineView.sortDescriptors];
	[self.outlineView reloadItem:nil reloadChildren:YES];
	
	NSInteger selectionRow = [self.outlineView rowForItem:node];
	[self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectionRow] byExtendingSelection:NO];
	[self.outlineView scrollRowToVisible:selectionRow];
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
