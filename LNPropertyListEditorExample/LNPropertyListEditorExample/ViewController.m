//
//  ViewController.m
//  LNPropertyListEditorExample
//
//  Created by Leo Natan on 4/12/18.
//  Copyright © 2018-2021 Leo Natan. All rights reserved.
//

#import "ViewController.h"
#import <LNPropertyListEditor/LNPropertyListEditor.h>

@interface ViewController () <LNPropertyListEditorDelegate, LNPropertyListEditorDataTransformer> @end

@implementation ViewController
{
	IBOutlet LNPropertyListEditor* _plistEditor;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	NSURL* propertyListURL = [[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"Contents/Info.plist"];
	id obj = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:propertyListURL] options:0 format:nil error:NULL];
	
	_plistEditor.delegate = self;
	_plistEditor.dataTransformer = self;
	
	_plistEditor.propertyListObject = obj;
	_plistEditor.allowsColumnSorting = YES;
	
//	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//		NSLog(@"Selected: %@", _plistEditor.selectedNode);
//		LNPropertyListNode* node = [_plistEditor.rootPropertyListNode.children filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key == 'yHelloNumber'"]].firstObject;
//		
//		[_plistEditor selectRowForNode:node];
//		[_plistEditor scrollRowForNodeToVisible:node];
//		NSLog(@"Selected: %@", _plistEditor.selectedNode);
//	});
}

#pragma mark LNPropertyListEditorDelegate

//- (BOOL)propertyListEditor:(LNPropertyListEditor *)editor canEditValueOfNode:(LNPropertyListNode*)node
//{
//	return NO;
//}

- (void)propertyListEditor:(LNPropertyListEditor *)editor didChangeNode:(LNPropertyListNode *)node changeType:(LNPropertyListNodeChangeType)changeType previousKey:(NSString *)previousKey
{
	switch(changeType)
	{
		case LNPropertyListNodeChangeTypeInsert:
			NSLog(@"🎉 Inserted %@", node);
			break;
		case LNPropertyListNodeChangeTypeDelete:
			NSLog(@"🗑 Deleted %@", node);
			break;
		case LNPropertyListNodeChangeTypeMove:
			NSLog(@"➡️ Moved %@", node);
			break;
		case LNPropertyListNodeChangeTypeUpdate:
			NSLog(@"🔄 Updated %@", node);
			break;
	}
}

#pragma mark LNPropertyListEditorDataTransformer

//- (nullable id)propertyListEditor:(LNPropertyListEditor *)editor displayValueForNode:(LNPropertyListNode*)node
//{
//	if(node.type == LNPropertyListNodeTypeData)
//	{
//		return @"Test";
//	}
//	
//	return nil;
//}
//
//- (nullable id)propertyListEditor:(LNPropertyListEditor *)editor storageValueForNode:(LNPropertyListNode*)node displayValue:(id)displayValue
//{
//	if(node.type == LNPropertyListNodeTypeData)
//	{
//		return [displayValue dataUsingEncoding:NSUTF8StringEncoding];
//	}
//	
//	return nil;
//}

@end
