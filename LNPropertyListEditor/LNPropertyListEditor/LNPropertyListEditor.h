//
//  LNPropertyListEditor.h
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/12/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LNPropertyListEditor/LNPropertyListNode.h>

typedef NS_ENUM(NSUInteger, LNPropertyListNodeChangeType) {
	LNPropertyListNodeChangeTypeInsert,
	LNPropertyListNodeChangeTypeDelete,
	LNPropertyListNodeChangeTypeMove,
	LNPropertyListNodeChangeTypeUpdate
};

NS_ASSUME_NONNULL_BEGIN

@class LNPropertyListEditor;

@protocol LNPropertyListEditorDelegate <NSObject>

@optional

/// Notifies the delegate that a node is about to change.
/// @param editor The property list editor.
/// @param node The node that will change.
/// @param changeType The change type.
/// @param previousKey The previous key, in case the key property has been updated.
- (void)propertyListEditor:(LNPropertyListEditor *)editor willChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(nullable NSString *)previousKey;
/// Notifies the delegate that a node has changed.
/// @param editor The property list editor.
/// @param node The node that has changed.
/// @param changeType The change type.
/// @param previousKey The previous key, in case the key property has been updated.
- (void)propertyListEditor:(LNPropertyListEditor *)editor didChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(nullable NSString *)previousKey;

/// Asks the delegate if the key of the specified node can be edited.
/// @param editor The property list editor.
/// @param node The current node.
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditKeyOfNode:(LNPropertyListNode*)node;
/// Asks the delegate if the type of the specified node can be edited.
/// @param editor The property list editor.
/// @param node The current node.
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditTypeOfNode:(LNPropertyListNode*)node;
/// Asks the delegate if the value of the specified node can be edited.
/// @param editor The property list editor.
/// @param node The current node.
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditValueOfNode:(LNPropertyListNode*)node;
/// Asks the delegate if the specified node can be deleted.
/// @param editor The property list editor.
/// @param node The current node.
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canDeleteNode:(LNPropertyListNode*)node;
/// Asks the delegate if it is possible add a child node in the specified node.
/// @param editor The property list editor.
/// @param node The current node.
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canAddChildNodeInNode:(LNPropertyListNode*)node;
/// Asks the delegate if the specified pasted node can be added as a child node of the specified node.
/// @param editor The property list editor.
/// @param pastedNode The pasted node.
/// @param node The current node.
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canPasteNode:(LNPropertyListNode*)pastedNode asChildOfNode:(LNPropertyListNode*)node;
/// Asks the delegate if the specified node can be moved as a child node of the specified node, at the specified index.
/// @param editor The property list editor.
/// @param movedNode The pasted node.
/// @param parentNode The current node.
/// @param index The index to paste at.
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canMoveNode:(LNPropertyListNode*)movedNode toParentNode:(LNPropertyListNode*)parentNode atIndex:(NSInteger)index;

/// Asks the delegate for a default value for a child node in the specified node.
/// @param editor The property list editor.
/// @param node The current node.
///
/// This can be either a valid property list or an LNPropertyListNode object.
- (nullable id)propertyListEditor:(LNPropertyListEditor *)editor defaultPropertyListForChildInNode:(LNPropertyListNode*)node;

@end

@protocol LNPropertyListEditorDataTransformer <NSObject>

@optional

/// Provides a display name for the specified node.
/// @param editor The property list editor.
/// @param node The current node.
- (nullable NSString*)propertyListEditor:(LNPropertyListEditor *)editor displayNameForNode:(LNPropertyListNode*)node;
/// Provides a display value for the specified node.
/// @param editor The property list editor.
/// @param node The current node.
///
/// This can be either a valid property list or an LNPropertyListNode object.
- (nullable id)propertyListEditor:(LNPropertyListEditor *)editor displayValueForNode:(LNPropertyListNode*)node;
/// Provides a storage value for the specified node and display value
/// @param editor The property list editor.
/// @param node The current node.
/// @param displayValue The current display value of the specified node.
- (nullable id)propertyListEditor:(LNPropertyListEditor *)editor storageValueForNode:(LNPropertyListNode*)node displayValue:(id)displayValue;

@end

IB_DESIGNABLE
@interface LNPropertyListEditor : NSView

/// The underlying edited property list object.
@property (nonatomic, copy) id propertyListObject;

/// Sets the type column as hidden.
@property (nonatomic, getter=isTypeColumnHidden) BOOL typeColumnHidden;

/// The root node of the edited property list.
@property (nonatomic, readonly) LNPropertyListNode* rootPropertyListNode;
/// Reloads the specified node and, optionally, its children.
/// @param node The node to reload.
/// @param reloadChildren Pass `true` to reload the node's children as well.
- (void)reloadNode:(LNPropertyListNode*)node reloadChildren:(BOOL)reloadChildren;

/// The property list editor delegate.
@property (nonatomic, weak) id<LNPropertyListEditorDelegate> delegate;
/// The property list editor data transformer.
@property (nonatomic, weak) id<LNPropertyListEditorDataTransformer> dataTransformer;

/// Adds a new item.
- (IBAction)add:(nullable id)sender;
/// Cuts the selected item.
///
/// Does nothing if there is no selection.
- (IBAction)cut:(nullable id)sender;
/// Copies the selected item.
///
/// Does nothing if there is no selection.
- (IBAction)copy:(nullable id)sender;
/// Pastes an item.
- (IBAction)paste:(nullable id)sender;
/// Deletes the selected item.
///
/// Does nothing if there is no selection.
- (IBAction)delete:(nullable id)sender;
/// Converts the selected item to boolean type.
///
/// Does nothing if there is no selection.
- (IBAction)boolean:(nullable id)sender;
/// Converts the selected item to number type.
///
/// Does nothing if there is no selection.
- (IBAction)number:(nullable id)sender;
/// Converts the selected item to string type.
///
/// Does nothing if there is no selection.
- (IBAction)string:(nullable id)sender;
/// Converts the selected item to date type.
///
/// Does nothing if there is no selection.
- (IBAction)date:(nullable id)sender;
/// Converts the selected item to data type.
///
/// Does nothing if there is no selection.
- (IBAction)data:(nullable id)sender;
/// Converts the selected item to array type.
///
/// Does nothing if there is no selection.
- (IBAction)array:(nullable id)sender;
/// Converts the selected item to dictionary type.
///
/// Does nothing if there is no selection.
- (IBAction)dictionary:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
