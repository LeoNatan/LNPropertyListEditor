//
//  NSObject+LNPropertyListValueSorting.m
//  LNPropertyListEditor
//
//  Created by Leo Natan on 5/5/21.
//  Copyright © 2021 Leo Natan. All rights reserved.
//

#import "NSObject+LNPropertyListValueSorting.h"
#import "LNPropertyListNode-Private.h"

@implementation NSObject (LNPropertyListValueSorting)

- (NSString*)_ln_stringValueForComparison
{
	if([self isKindOfClass:NSString.class])
	{
		return (NSString*)self;
	}
	else if([self isKindOfClass:NSClassFromString(@"__NSCFBoolean")])
	{
		return [(NSNumber*)self boolValue] ? @"YES" : @"NO";
	}
	else if([self isKindOfClass:NSNumber.class])
	{
		return [LNPropertyListNode._numberFormatter stringFromNumber:(NSNumber*)self];
	}
	else if([self isKindOfClass:NSData.class])
	{
		return @"<Data>";
	}
	else if([self isKindOfClass:NSDate.class])
	{
		return [NSDateFormatter localizedStringFromDate:(NSDate*)self dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
	}
	
	return @"";
}


- (NSComparisonResult)_ln_compareValue:(NSObject*)other
{
	return [[self _ln_stringValueForComparison] localizedCaseInsensitiveCompare:[other _ln_stringValueForComparison]];
}

@end
