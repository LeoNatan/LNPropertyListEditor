//
//  LNPropertyListEditor.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListEditor.h"
#import "LNPropertyListNode-Private.h"
#import "LNPropertyListRowView.h"
#import "LNPropertyListCellView.h"

static NSPasteboardType LNPropertyListNodePasteboardType = @"com.LeoNatan.LNPropertyListNode";

@import ObjectiveC;

@interface LNPropertyListEditor () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate>
{
	
	IBOutlet NSMenu* _menuItem;
	
	IBOutlet NSTableColumn* _keyColumn;
	IBOutlet NSTableColumn* _typeColumn;
	IBOutlet NSTableColumn* _valueColumn;
	
	NSUndoManager* _undoManager;
}

@property (nonatomic, weak) IBOutlet NSOutlineView* outlineView;

@end

@implementation LNPropertyListEditor

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

- (void)setPropertyList:(id)propertyList
{
	_rootPropertyListNode = [[LNPropertyListNode alloc] initWithPropertyList:propertyList];
	
	[_outlineView reloadData];
}

- (id)propertyList
{
	return _rootPropertyListNode.propertyList;
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
	
	[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeMove previousKey:oldKey];
	
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
	
	[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeUpdate previousKey:node.key];
	
	LNPropertyListNodeType oldType = node.type;
	id oldValue = node.value;
	id oldChildren = node.children;
	
	node.type = type;
	node.value = value;
	node.children = children;
	
	[_outlineView reloadItem:node reloadChildren:YES];
	
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _setType:oldType children:oldChildren value:oldValue forSender:@(row)];
	}];
}

- (void)_convertToType:(LNPropertyListNodeType)newType forSender:(id)sender
{
	[self _setType:newType children:(newType == LNPropertyListNodeTypeArray || newType == LNPropertyListNodeTypeDictionary ? [NSMutableArray new] : nil) value:[LNPropertyListNode defaultValueForType:newType] forSender:sender];
}

- (void)_updateValue:(id)value ofNode:(LNPropertyListNode*)node
{
	if([node.value isEqual:value])
	{
		return;
	}
	
	id oldValue = node.value;
	node.value = value;
	
	[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeUpdate previousKey:node.key];
	
	LNPropertyListCellView* cellView = [[_outlineView rowViewAtRow:[_outlineView rowForItem:node] makeIfNecessary:NO] viewAtColumn:2];
	if(node.type == LNPropertyListNodeTypeBoolean)
	{
		[cellView setControlWithBoolean:[value boolValue]];
	}
	else
	{
		[cellView setControlWithString:[LNPropertyListNode stringValueOfNode:node] setToolTip:cellView.textField.editable];
	}
	
	[_undoManager registerUndoWithTarget:self handler:^(LNPropertyListEditor* _Nonnull target) {
		[target _updateValue:oldValue ofNode:node];
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
	
	[self.delegate propertyListEditor:self willChangeNode:node changeType:LNPropertyListNodeChangeTypeInsert previousKey:node.key];
	
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
	
	[_outlineView beginUpdates];
	
	LNPropertyListNode* deletedNode = [_outlineView itemAtRow:row];
	
	[self.delegate propertyListEditor:self willChangeNode:deletedNode changeType:LNPropertyListNodeChangeTypeDelete previousKey:deletedNode.key];
	
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
		return YES;
	}
	
	if(menuItem.action == @selector(paste:))
	{
		return [NSPasteboard.generalPasteboard canReadItemWithDataConformingToTypes:@[LNPropertyListNodePasteboardType]];
	}
	
	return menuItem.action && [self respondsToSelector:menuItem.action] && ([self _rowForSender:menuItem beep:NO] != -1 || menuItem.action == @selector(add:));
}

- (BOOL)_nodeContainsChildrenWithKey:(NSString*)key inNode:(LNPropertyListNode*)node excludingNode:(LNPropertyListNode*)excludedNode
{
	return [node.children filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key == %@ && self != %@", key, excludedNode]].count > 0;
}

- (IBAction)add:(id)sender
{
	LNPropertyListNode* insertedNode = [[LNPropertyListNode alloc] initWithPropertyList:@""];
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
	
	[self _updateValue:@([[sender menu].itemArray indexOfObject:sender] == 1) ofNode:node];
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
		return _rootPropertyListNode.type == LNPropertyListNodeTypeArray || _rootPropertyListNode.type == LNPropertyListNodeTypeDictionary ? _rootPropertyListNode.children.count : 1;
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
	return [LNPropertyListRowView new];
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
		editable = item.parent == nil || item.parent.type == LNPropertyListNodeTypeDictionary;
	}
	else if(tableColumn == _typeColumn)
	{
		identifier = @"TypeCell";
		value = [LNPropertyListNode stringForType:item.type];
	}
	else if(tableColumn == _valueColumn)
	{
		if(item.type == LNPropertyListNodeTypeBoolean)
		{
			identifier = @"BoolCell";
		}
		else
		{
			identifier = @"ValueCell";
		}
		
		editable = !(item.type == LNPropertyListNodeTypeArray || item.type == LNPropertyListNodeTypeDictionary);
		value = [LNPropertyListNode stringValueOfNode:item];
	}
	
	cellView = [outlineView makeViewWithIdentifier:identifier owner:nil];
	if([cellView.identifier isEqualToString:@"BoolCell"])
	{
		[cellView setControlWithBoolean:[item.value boolValue]];
	}
	else
	{
		[cellView setControlWithString:value setToolTip:(tableColumn == _keyColumn || (tableColumn == _valueColumn && editable))];
	}
	cellView.textField.selectable = cellView.textField.editable = editable;
	cellView.textField.delegate = self;
	
	return cellView;
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
			[self _updateValue:newValue ofNode:node];
		}
		else
		{
			textField.stringValue = [LNPropertyListNode stringValueOfNode:node];
			[(LNPropertyListCellView*)textField.superview flashError];
		}
	}
}

@end
