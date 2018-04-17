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
	IBOutlet NSOutlineView* _outlineView;
	IBOutlet NSMenu* _menuItem;
	
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

- (void)setPropertyList:(id)propertyList
{
	_rootPropertyListNode = [[LNPropertyListNode alloc] initWithPropertyList:propertyList];
	
	[_outlineView reloadData];
}

- (id)propertyList
{
	return _rootPropertyListNode.propertyList;
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

- (void)_insertNode:(LNPropertyListNode*)insertedNode sender:(id)sender
{
	NSInteger row = [self _rowForSender:sender beep:NO];
	if(row == -1)
	{
		row = _rootPropertyListNode.children.count - 1;
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
	LNPropertyListNode* selectedItem = [_outlineView itemAtRow:_outlineView.selectedRow];
	
	NSInteger row = [self _rowForSender:sender beep:YES];
	if(row == -1)
	{
		return;
	}
	
	[_outlineView beginUpdates];
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	LNPropertyListNode* parentNodeInOutline = node.parent != _rootPropertyListNode ? node.parent : nil;
	
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

- (void)_convertToType:(LNPropertyListNodeType)newType forSender:(id)sender
{
	NSInteger row = [self _rowForSender:sender beep:YES];
	if(row == -1)
	{
		return;
	}
	
	LNPropertyListNode* node = [_outlineView itemAtRow:row];
	[LNPropertyListNode resetNode:node forNewType:newType];
	[_outlineView reloadItem:node reloadChildren:YES];
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
	
	node.value = [LNPropertyListNode convertString:[sender title] toObjectOfType:LNPropertyListNodeTypeBoolean];
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
	[cellView setControlWithString:value];
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
			node.key = textField.stringValue;
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
			node.value = newValue;
		}
		else
		{
			textField.stringValue = [LNPropertyListNode stringValueOfNode:node];
			[(LNPropertyListCellView*)textField.superview flashError];
		}
	}
}

@end
