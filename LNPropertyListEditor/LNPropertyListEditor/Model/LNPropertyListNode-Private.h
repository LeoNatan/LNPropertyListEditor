//
//  LNPropertyListNode.h
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/12/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LNPropertyListNode.h"

@interface LNPropertyListNode ()

@property (nonatomic, strong) id _cachedDisplayKey;
@property (nonatomic, strong) id _cachedDisplayValue;

+ (LNPropertyListNodeType)_typeForObject:(id)obj;
+ (NSString*)stringForType:(LNPropertyListNodeType)type;
+ (LNPropertyListNodeType)typeForString:(NSString*)str;
+ (id)defaultValueForType:(LNPropertyListNodeType)type;
+ (id)convertString:(NSString*)str toObjectOfType:(LNPropertyListNodeType)type;
+ (NSString*)stringKeyOfNode:(LNPropertyListNode*)node;
+ (NSString*)stringValueOfNode:(LNPropertyListNode*)node;

- (void)_sortUsingDescriptors:(NSArray<NSSortDescriptor *> *)descriptors;

@end
