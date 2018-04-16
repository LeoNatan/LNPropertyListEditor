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

@interface LNPropertyListEditor () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate, LNPropertyListCellViewDelegate>
{
	IBOutlet NSOutlineView* _outlineView;
	
	IBOutlet NSTableColumn* _keyColumn;
	IBOutlet NSTableColumn* _typeColumn;
	IBOutlet NSTableColumn* _valueColumn;
}

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
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if(menuItem.action == @selector(deleteItem:))
	{
		return _outlineView.selectedRow != -1;
	}
	
	return NO;
}

- (IBAction)addItem:(id)sender
{
	NSInteger row = [_outlineView rowForView:sender];
	if(row == -1)
	{
		row = _outlineView.selectedRow;
	}
	if(row == -1)
	{
		row = _propertyListNode.children.count - 1;
	}
	
	[_outlineView beginUpdates];
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	NSUInteger insertionRow;
	
	LNPropertyListNode* parentNode;
	if([_outlineView isItemExpanded:node])
	{
		parentNode = node;
		insertionRow = 0;
	}
	else
	{
		parentNode = [node parent];
		insertionRow = [parentNode.children indexOfObject:node] + 1;
	}
	LNPropertyListNode* parentNodeInOutline = parentNode != _propertyListNode ? parentNode : nil;
	
	LNPropertyListNode* insertedNode = [[LNPropertyListNode alloc] initWithPropertyList:@""];
	insertedNode.parent = parentNode;
	if(parentNode.type == LNPropertyListNodeTypeDictionary)
	{
		insertedNode.key = @"New Item";
	}
	
	[parentNode.children insertObject:insertedNode atIndex:insertionRow];
	[_outlineView insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionRow] inParent:parentNodeInOutline withAnimation:NSTableViewAnimationSlideDown];
	
	[_outlineView reloadItem:parentNode];
	if(parentNode.type == LNPropertyListNodeTypeArray)
	{
		[[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertionRow, parentNode.children.count - insertionRow)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			[self->_outlineView reloadItem:parentNode.children[idx]];
		}];
	}
	
	[_outlineView endUpdates];
	
	[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_outlineView rowForItem:insertedNode]] byExtendingSelection:NO];
}

- (IBAction)deleteItem:(id)sender
{
	LNPropertyListNode* selectedItem = [_outlineView itemAtRow:[_outlineView selectedRow]];
	
	NSInteger row = [_outlineView rowForView:sender];
	if(row == -1)
	{
		row = _outlineView.selectedRow;
	}
	
	if(row == -1)
	{
		NSBeep();
		return;
	}
	
	[_outlineView beginUpdates];
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	LNPropertyListNode* parentNodeInOutline = node.parent != _propertyListNode ? node.parent : nil;
	
	NSUInteger deletionRow = [node.parent.children indexOfObject:node];
	
	[node.parent.children removeObjectAtIndex:deletionRow];
	[_outlineView removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:deletionRow] inParent:parentNodeInOutline withAnimation:NSTableViewAnimationSlideUp];
	
	if(parentNodeInOutline != nil)
	{
		[_outlineView reloadItem:parentNodeInOutline];
	}
	if(node.parent.type == LNPropertyListNodeTypeArray)
	{
		[[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(deletionRow, node.parent.children.count - deletionRow)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			[self->_outlineView reloadItem:node.parent.children[idx]];
		}];
	}
	
	[self->_outlineView endUpdates];
	
	[_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_outlineView rowForItem:selectedItem]] byExtendingSelection:NO];
}

- (void)setPropertyList:(id)propertyList
{
	_propertyListNode = [[LNPropertyListNode alloc] initWithPropertyList:propertyList];
	
	[_outlineView reloadData];
}

- (id)propertyList
{
	return _propertyListNode.propertyList;
}

#pragma mark NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(LNPropertyListNode*)item
{
	if(item == nil)
	{
		return _propertyListNode.type == LNPropertyListNodeTypeArray || _propertyListNode.type == LNPropertyListNodeTypeDictionary ? _propertyListNode.children.count : 1;
	}
	
	return item.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(LNPropertyListNode*)item
{
	if(item == nil)
	{
		item = _propertyListNode;
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
	[cellView setControlWithString:value];
	cellView.textField.selectable = cellView.textField.editable = editable;
	cellView.textField.delegate = self;
	cellView.delegate = self;
	
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
		node.key = textField.stringValue;
	}
	else if(column == 2)
	{
		id newValue = [LNPropertyListNode convertString:textField.stringValue toObjectOfType:node.type];
		if(newValue != nil)
		{
			node.value = newValue;
		}
		else
		{
			textField.stringValue = [LNPropertyListNode stringValueOfNode:node];
			[(LNPropertyListCellView*)textField.superview flashError];
		}
	}
}

#pragma mark LNPropertyListCellViewDelegate

- (void)typeButtonValueDidChangeForPropertyListCell:(LNPropertyListCellView *)cell
{
	NSUInteger row = [_outlineView rowForView:cell];
	NSUInteger column = [_outlineView columnForView:cell];
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	
	NSString* value = cell.typeButton.title;
	
	if(column == 1)
	{
		LNPropertyListNodeType newType = [LNPropertyListNode typeForString:value];
		[LNPropertyListNode resetNode:node forNewType:newType];
		[_outlineView reloadItem:node reloadChildren:YES];
	}
	else if(column == 2)
	{
		node.value = [LNPropertyListNode convertString:value toObjectOfType:LNPropertyListNodeTypeBoolean];
	}
}

@end
