//
//  LNPropertyListNode.h
//  LNPropertyListEditor
//
//  Created by Leo Natan on 4/12/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LNPropertyListNode.h"

#import <AppKit/AppKit.h>

extern NSString* const LNPropertyListNodePasteboardType;
extern NSString* const LNPropertyListNodeXcodeKeyType;

@interface LNPropertyListNode () <NSPasteboardReading>

@property (nonatomic, strong) id _cachedDisplayKey;
@property (nonatomic, strong) id _cachedDisplayValue;
@property (nonatomic, readonly) LNPropertyListNodeType _appropriateType;

+ (NSNumberFormatter*)_numberFormatter;

+ (LNPropertyListNodeType)_typeForObject:(id)obj;
+ (NSString*)stringForType:(LNPropertyListNodeType)type;
+ (LNPropertyListNodeType)typeForString:(NSString*)str;
+ (id)defaultValueForType:(LNPropertyListNodeType)type;
+ (id)convertString:(NSString*)str toObjectOfType:(LNPropertyListNodeType)type;
+ (NSString*)stringKeyOfNode:(LNPropertyListNode*)node;
+ (NSString*)stringValueOfNode:(LNPropertyListNode*)node;

+ (instancetype)_nodeFromPasteboard:(NSPasteboard*)pasteboard;
+ (void)_clearPasteboardMapping;

- (void)_setObject:(id)object;

- (void)_sortUsingDescriptors:(NSArray<NSSortDescriptor *> *)descriptors validator:(BOOL (^)(LNPropertyListNode*))validator callback:(void (^)(LNPropertyListNode*, BOOL))callback;

- (id<NSPasteboardWriting>)pasteboardWriter;

@end

@interface LNPropertyListNodePasteboardWriter : NSObject <NSPasteboardWriting>

- (instancetype)initWithNode:(LNPropertyListNode*)node;

@end
