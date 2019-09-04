//
//  LNPropertyListNode.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListNode-Private.h"

@implementation LNPropertyListNode

+ (BOOL)supportsSecureCoding
{
	return YES;
}

+ (NSNumberFormatter*)_numberFormatter
{
	static NSNumberFormatter* __numberFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__numberFormatter = [NSNumberFormatter new];
		__numberFormatter.numberStyle = NSNumberFormatterNoStyle;
	});
	return __numberFormatter;
}

+ (LNPropertyListNodeType)_typeForObject:(id)obj
{
	if([obj isKindOfClass:[NSArray class]])
	{
		return LNPropertyListNodeTypeArray;
	}
	if([obj isKindOfClass:[NSDictionary class]])
	{
		return LNPropertyListNodeTypeDictionary;
	}
	if([obj isKindOfClass:[NSString class]])
	{
		return LNPropertyListNodeTypeString;
	}
	if([obj isKindOfClass:[NSDate class]])
	{
		return LNPropertyListNodeTypeDate;
	}
	if([obj isKindOfClass:[NSData class]])
	{
		return LNPropertyListNodeTypeData;
	}
	if([obj isKindOfClass:NSClassFromString(@"__NSCFBoolean")])
	{
		return LNPropertyListNodeTypeBoolean;
	}
	if([obj isKindOfClass:[NSNumber class]])
	{
		return LNPropertyListNodeTypeNumber;
	}
	
	return LNPropertyListNodeTypeUnknown;
}

+ (NSString *)stringForType:(LNPropertyListNodeType)type
{
	switch (type)
	{
		case LNPropertyListNodeTypeUnknown:
			return nil;
		case LNPropertyListNodeTypeArray:
			return @"Array";
		case LNPropertyListNodeTypeDictionary:
			return @"Dictionary";
		case LNPropertyListNodeTypeBoolean:
			return @"Boolean";
		case LNPropertyListNodeTypeDate:
			return @"Date";
		case LNPropertyListNodeTypeData:
			return @"Data";
		case LNPropertyListNodeTypeNumber:
			return @"Number";
		case LNPropertyListNodeTypeString:
			return @"String";
	}
}

+ (LNPropertyListNodeType)typeForString:(NSString*)str
{
	if([str isEqualToString:@"Array"])
	{
		return LNPropertyListNodeTypeArray;
	}
	if([str isEqualToString:@"Dictionary"])
	{
		return LNPropertyListNodeTypeDictionary;
	}
	if([str isEqualToString:@"String"])
	{
		return LNPropertyListNodeTypeString;
	}
	if([str isEqualToString:@"Date"])
	{
		return LNPropertyListNodeTypeDate;
	}
	if([str isEqualToString:@"Data"])
	{
		return LNPropertyListNodeTypeData;
	}
	if([str isEqualToString:@"Boolean"])
	{
		return LNPropertyListNodeTypeBoolean;
	}
	if([str isEqualToString:@"Number"])
	{
		return LNPropertyListNodeTypeNumber;
	}
	
	return LNPropertyListNodeTypeUnknown;
}

+ (id)defaultValueForType:(LNPropertyListNodeType)type;
{
	switch (type)
	{
		case LNPropertyListNodeTypeUnknown:
			return nil;
		case LNPropertyListNodeTypeArray:
		case LNPropertyListNodeTypeDictionary:
			return nil;
		case LNPropertyListNodeTypeBoolean:
			return @NO;
		case LNPropertyListNodeTypeDate:
			return [NSDate date];
		case LNPropertyListNodeTypeData:
			return [NSData data];
		case LNPropertyListNodeTypeNumber:
			return @0;
		case LNPropertyListNodeTypeString:
			return @"";
	}
}

+ (id)convertString:(NSString*)str toObjectOfType:(LNPropertyListNodeType)type
{
	switch (type)
	{
		case LNPropertyListNodeTypeUnknown:
			return nil;
		case LNPropertyListNodeTypeArray:
			return nil;
		case LNPropertyListNodeTypeDictionary:
			return nil;
		case LNPropertyListNodeTypeBoolean:
			return [str isEqualToString:@"YES"] ? @YES : @NO;
		case LNPropertyListNodeTypeDate:
			return nil;
		case LNPropertyListNodeTypeData:
			return nil;
		case LNPropertyListNodeTypeNumber:
			return [LNPropertyListNode._numberFormatter numberFromString:str];
		case LNPropertyListNodeTypeString:
			return str;
	}
}

+ (NSString*)stringValueOfNode:(LNPropertyListNode*)node
{
	id valueToTranslate = node._cachedDisplayValue ?: node.value;
	NSArray* childrenToTranslate = [node._cachedDisplayValue isKindOfClass:[NSArray class]] ? node._cachedDisplayValue : [node._cachedDisplayValue isKindOfClass:[NSDictionary class]] ? [node._cachedDisplayValue allKeys] : node.children;
	LNPropertyListNodeType typeToTranslate = node._cachedDisplayValue ? [self _typeForObject:node._cachedDisplayValue] : node.type;
	
	switch (typeToTranslate)
	{
		case LNPropertyListNodeTypeUnknown:
			return nil;
		case LNPropertyListNodeTypeArray:
		case LNPropertyListNodeTypeDictionary:
			return [NSString stringWithFormat:NSLocalizedString(@"(%lu items)", @""), childrenToTranslate.count];
		case LNPropertyListNodeTypeBoolean:
			return [valueToTranslate boolValue] ? @"YES" : @"NO";
		case LNPropertyListNodeTypeDate:
			return nil;
		case LNPropertyListNodeTypeData:
			return @"<Data>";
		case LNPropertyListNodeTypeNumber:
			return [LNPropertyListNode._numberFormatter stringFromNumber:valueToTranslate];
		case LNPropertyListNodeTypeString:
			return valueToTranslate;
	}
}

+ (NSString*)stringKeyOfNode:(LNPropertyListNode*)node
{
	switch (node.parent.type)
	{
		case LNPropertyListNodeTypeArray:
			return [NSString stringWithFormat:NSLocalizedString(@"Item %lu", @""), [node.parent.children indexOfObject:node]];
		default:
			return node.key;
	}
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	
	if(self)
	{
		self.key = [aDecoder decodeObjectForKey:@"key"];
		self.type = [[aDecoder decodeObjectForKey:@"type"] unsignedIntegerValue];
		self.value = [aDecoder decodeObjectForKey:@"value"];
		self.children = [aDecoder decodeObjectForKey:@"children"];
		
		[self.children enumerateObjectsUsingBlock:^(LNPropertyListNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
			obj.parent = self;
		}];
	}
	
	return self;
}

- (instancetype)initWithDictionary:(NSDictionary<NSString*, id>*)dictionary
{
	self = [super init];
	
	if(self)
	{
		self.type = LNPropertyListNodeTypeDictionary;
		self.children = [NSMutableArray new];
		
		[dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
			LNPropertyListNode* childNode = [[LNPropertyListNode alloc] initWithObject:obj];
			childNode.key = key;
			childNode.parent = self;
			[self.children addObject:childNode];
		}];
	}
	
	return self;
}

- (instancetype)initWithArray:(NSArray<id>*)array
{
	self = [super init];
	
	self.type = LNPropertyListNodeTypeArray;
	self.children = [NSMutableArray new];
	
	[array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		LNPropertyListNode* childNode = [[LNPropertyListNode alloc] initWithObject:obj];
		childNode.parent = self;
		[self.children addObject:childNode];
	}];
	
	return self;
}

- (instancetype)initWithObject:(id)obj
{
	if(obj == nil)
	{
		return nil;
	}
	
	LNPropertyListNodeType type = [LNPropertyListNode _typeForObject:obj];
	
	if(type == LNPropertyListNodeTypeDictionary)
	{
		return [self initWithDictionary:obj];
	}
	if(type == LNPropertyListNodeTypeArray)
	{
		return [self initWithArray:obj];
	}
	
	self = [super init];
	
	if(self)
	{
		self.type = type;
		self.value = obj;
	}
	
	return self;
}

- (instancetype)initWithPropertyList:(id)obj
{
	return [self initWithObject:obj];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.key forKey:@"key"];
	[aCoder encodeObject:@(self.type) forKey:@"type"];
	[aCoder encodeObject:self.value forKey:@"value"];
	[aCoder encodeObject:self.children forKey:@"children"];
}

- (NSString *)description
{
	NSMutableString* builder = [NSMutableString stringWithFormat:@"<%@ %p", self.className, self];
	
	if(self.key != nil)
	{
		[builder appendFormat:@" key: “%@”", self.key];
	}
	
	[builder appendFormat:@" type: “%@”", [LNPropertyListNode stringForType:self.type]];
	
	if(self.type == LNPropertyListNodeTypeDictionary || self.type == LNPropertyListNodeTypeArray)
	{
		[builder appendFormat:@" children: “%lu items”", self.children.count];
	}
	else
	{
		[builder appendFormat:@" value: “%@”", [self.value description]];
	}
	
	[builder appendString:@">"];
	
	return builder;
}

- (NSDictionary*)_dictionaryObject
{
	NSMutableDictionary* rv = [NSMutableDictionary new];
	
	[self.children enumerateObjectsUsingBlock:^(LNPropertyListNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		rv[obj.key] = obj.propertyList;
	}];
	
	return rv.copy;
}

- (NSArray*)_arrayObject
{
	NSMutableArray* rv = [NSMutableArray new];
	
	[self.children enumerateObjectsUsingBlock:^(LNPropertyListNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		[rv addObject:obj.propertyList];
	}];
	
	return rv.copy;
}

- (id)propertyList
{
	if(self.type == LNPropertyListNodeTypeDictionary)
	{
		return self._dictionaryObject;
	}
	if(self.type == LNPropertyListNodeTypeArray)
	{
		return self._arrayObject;
	}
	
	return self.value;
}

- (LNPropertyListNode*)childNodeContainingDescendantNode:(LNPropertyListNode*)descendantNode;
{
	LNPropertyListNode* parent = descendantNode;
	
	while(parent != nil && [self.children containsObject:parent] == NO)
	{
		parent = parent.parent;
	}
	
	return parent;
}

- (LNPropertyListNode*)childNodeForKey:(NSString*)key
{
	return [self.children filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key == %@", key]].firstObject;
}

- (void)_sortUsingDescriptors:(NSArray<NSSortDescriptor *> *)descriptors
{
	if(self.type != LNPropertyListNodeTypeDictionary)
	{
		return;
	}
	
	[self.children sortUsingDescriptors:descriptors];
}

@end
