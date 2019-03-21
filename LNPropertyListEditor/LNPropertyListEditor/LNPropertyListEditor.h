//
//  LNPropertyListEditor.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LNPropertyListEditor/LNPropertyListNode.h>

@protocol LNPropertyListEditorDelegate;
@protocol LNPropertyListEditorDataTransformer;

IB_DESIGNABLE
@interface LNPropertyListEditor : NSView

/**
 * The underlying edited property list.
 */
@property (nonatomic, copy) id<NSCopying> propertyList;

@property (nonatomic, getter=isTypeColumnHidden) BOOL typeColumnHidden;

/**
 * The root node of the edited property list.
 */
@property (nonatomic, readonly) LNPropertyListNode* rootPropertyListNode;
- (void)reloadNode:(LNPropertyListNode*)node reloadChildren:(BOOL)reloadChildren;

@property (nonatomic, weak) id<LNPropertyListEditorDelegate> delegate;
@property (nonatomic, weak) id<LNPropertyListEditorDataTransformer> dataTransformer;

/**
 * Adds a new item.
 */
- (IBAction)add:(id)sender;
/**
 * Cuts the selected item.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)cut:(id)sender;
/**
 * Copies the selected item.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)copy:(id)sender;
/**
 * Pastes an item.
 */
- (IBAction)paste:(id)sender;
/**
 * Deletes the selected item.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)delete:(id)sender;
/**
 * Converts the selected item to boolean type.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)boolean:(id)sender;
/**
 * Converts the selected item to number type.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)number:(id)sender;
/**
 * Converts the selected item to string type.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)string:(id)sender;
/**
 * Converts the selected item to date type.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)date:(id)sender;
/**
 * Converts the selected item to data type.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)data:(id)sender;
/**
 * Converts the selected item to array type.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)array:(id)sender;
/**
 * Converts the selected item to dictionary type.
 *
 * Does nothing if there is no selection.
 */
- (IBAction)dictionary:(id)sender;

@end

@protocol LNPropertyListEditorDelegate <NSObject>

typedef NS_ENUM(NSUInteger, LNPropertyListNodeChangeType) {
	LNPropertyListNodeChangeTypeInsert,
	LNPropertyListNodeChangeTypeDelete,
	LNPropertyListNodeChangeTypeMove,
	LNPropertyListNodeChangeTypeUpdate
};

@optional

- (void)propertyListEditor:(LNPropertyListEditor *)editor willChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey;
- (void)propertyListEditor:(LNPropertyListEditor *)editor didChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey;

- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditKeyOfNode:(LNPropertyListNode*)node;
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditTypeOfNode:(LNPropertyListNode*)node;
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditValueOfNode:(LNPropertyListNode*)node;
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canDeleteNode:(LNPropertyListNode*)node;
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canAddNewNodeInNode:(LNPropertyListNode*)node;
- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canPasteNode:(LNPropertyListNode*)pastedNode inNode:(LNPropertyListNode*)node;

//This can be either a valid property list or an LNPropertyListNode object.
- (id)propertyListEditor:(LNPropertyListEditor *)editor defaultPropertyListForAddingInNode:(LNPropertyListNode*)node;

@end

@protocol LNPropertyListEditorDataTransformer <NSObject>

@optional

- (NSString*)propertyListEditor:(LNPropertyListEditor *)editor displayNameForNode:(LNPropertyListNode*)node;
- (id)propertyListEditor:(LNPropertyListEditor *)editor transformValueForDisplay:(LNPropertyListNode*)node;
- (NSString*)propertyListEditor:(LNPropertyListEditor *)editor transformValueForStorage:(LNPropertyListNode*)node displayValue:(id)displayValue;

@end
