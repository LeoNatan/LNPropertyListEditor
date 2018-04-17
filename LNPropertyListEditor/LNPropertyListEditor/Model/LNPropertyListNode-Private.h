//
//  LNPropertyListNode.h
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LNPropertyListNode.h"

@interface LNPropertyListNode ()

+ (NSString*)stringForType:(LNPropertyListNodeType)type;
+ (LNPropertyListNodeType)typeForString:(NSString*)str;
+ (id)defaultValueForType:(LNPropertyListNodeType)type;
+ (id)convertString:(NSString*)str toObjectOfType:(LNPropertyListNodeType)type;
+ (NSString*)stringKeyOfNode:(LNPropertyListNode*)node;
+ (NSString*)stringValueOfNode:(LNPropertyListNode*)node;

@end
