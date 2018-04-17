//
//  LNPropertyListNode.m
//  LNPropertyListEditor
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "LNPropertyListNode-Private.h"

static NSDateFormatter* __dateFormatter;
static NSNumberFormatter* __numberFormatter;

@implementation LNPropertyListNode

+ (BOOL)supportsSecureCoding
{
	return YES;
}

+ (void)load
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__dateFormatter = [NSDateFormatter new];
		__dateFormatter.dateStyle = NSDateFormatterMediumStyle;
		__dateFormatter.timeStyle = NSDateFormatterMediumStyle;
		__numberFormatter = [NSNumberFormatter new];
		__numberFormatter.numberStyle = NSNumberFormatterNoStyle;
	});
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
	
	[NSException raise:NSInvalidArgumentException format:@"Not property list class: “%@”", [obj class]];
	return LNPropertyListNodeTypeUnknown;
}

+ (NSString *)stringForType:(LNPropertyListNodeType)type
{
	switch (type)
	{
		case LNPropertyListNodeTypeUnknown:
			return @"Unknown";
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

+ (void)resetNode:(LNPropertyListNode*)node forNewType:(LNPropertyListNodeType)type;
{
	if(node.type == type)
	{
		return;
	}
	
	switch (type)
	{
		case LNPropertyListNodeTypeUnknown:
			node.value = nil;
			break;
		case LNPropertyListNodeTypeArray:
			node.value = nil;
			break;
		case LNPropertyListNodeTypeDictionary:
			node.value = nil;
			break;
		case LNPropertyListNodeTypeBoolean:
			node.value = @NO;
			break;
		case LNPropertyListNodeTypeDate:
			node.value = [NSDate date];
			break;
		case LNPropertyListNodeTypeData:
			node.value = [NSData data];
			break;
		case LNPropertyListNodeTypeNumber:
			node.value = @0;
			break;
		case LNPropertyListNodeTypeString:
			node.value = @"";
			break;
	}
	
	if(node.value == nil && type != LNPropertyListNodeTypeUnknown)
	{
		node.children = [NSMutableArray new];
	}
	
	node.type = type;
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
			return [__dateFormatter dateFromString:str];
		case LNPropertyListNodeTypeData:
			return nil;
		case LNPropertyListNodeTypeNumber:
			return [__numberFormatter numberFromString:str];
		case LNPropertyListNodeTypeString:
			return str;
	}
}

+ (NSString*)stringValueOfNode:(LNPropertyListNode*)node
{
	switch (node.type)
	{
		case LNPropertyListNodeTypeUnknown:
			return nil;
		case LNPropertyListNodeTypeArray:
		case LNPropertyListNodeTypeDictionary:
			return [NSString stringWithFormat:NSLocalizedString(@"(%lu items)", @""), node.children.count];
		case LNPropertyListNodeTypeBoolean:
			return [node.value boolValue] ? @"YES" : @"NO";
		case LNPropertyListNodeTypeDate:
			return [__dateFormatter stringFromDate:node.value];
		case LNPropertyListNodeTypeData:
			return @"<Data>";
		case LNPropertyListNodeTypeNumber:
			return [__numberFormatter stringFromNumber:node.value];
		case LNPropertyListNodeTypeString:
			return node.value;
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

@end
