//
//  LNPropertyListNode.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
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

@interface LNPropertyListNode : NSObject <NSSecureCoding>

- (instancetype)initWithPropertyList:(id)obj;

@property (nonatomic, strong) NSString* key;
@property (nonatomic) LNPropertyListNodeType type;

@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSMutableArray<LNPropertyListNode*>* children;
- (LNPropertyListNode*)childNodeContainingDescendantNode:(LNPropertyListNode*)descendantNode;
- (LNPropertyListNode*)childNodeForKey:(NSString*)key;

@property (nonatomic, weak) LNPropertyListNode* parent;

@property (nonatomic, strong, readonly) id propertyList;


@end
