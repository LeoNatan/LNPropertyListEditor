//
//  LNPropertyListNode.h
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/12/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.

//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LNPropertyListNodeType) {
	LNPropertyListNodeTypeUnknown,
	
	LNPropertyListNodeTypeArray,
	LNPropertyListNodeTypeDictionary,
	LNPropertyListNodeTypeBoolean,
	LNPropertyListNodeTypeDate,
	LNPropertyListNodeTypeData,
	LNPropertyListNodeTypeNumber,
	LNPropertyListNodeTypeString,
};

NS_ASSUME_NONNULL_BEGIN

@interface LNPropertyListNode : NSObject <NSSecureCoding, NSCopying>

/// Returns a property list node representing the specified object.
/// @param obj An object to be represented by the node.
- (instancetype)initWithPropertyListObject:(id)obj;

/// The key of the property list node.
@property (nonatomic, strong, nullable) NSString* key;
/// The type of the property list node.
@property (nonatomic) LNPropertyListNodeType type;
/// The value of the property list object.
@property (nonatomic, strong) id value;

/// The children of the property list node.
@property (nonatomic, strong, nullable) NSMutableArray<LNPropertyListNode*>* children;


/// Returns the child node containing the specified descendant node.
/// @param descendantNode The descendant node to search for.
- (nullable LNPropertyListNode*)childNodeContainingDescendantNode:(LNPropertyListNode*)descendantNode;

/// Returns the child node with the specified key.
/// @param key The key of the child node.
- (nullable LNPropertyListNode*)childNodeForKey:(NSString*)key;

/// The parent of the property list node.
@property (nonatomic, weak, nullable) LNPropertyListNode* parent;

/// The object, represented by the property list node.
@property (nonatomic, strong, readonly) id propertyListObject;

@end

NS_ASSUME_NONNULL_END
