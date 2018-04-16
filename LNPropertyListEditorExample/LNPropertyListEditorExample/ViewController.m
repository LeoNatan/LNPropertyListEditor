//
//  ViewController.m
//  LNPropertyListEditorExample
//
//  Created by Leo Natan (Wix) on 4/12/18.
//  Copyright © 2018 Leo Natan. All rights reserved.
//

#import "ViewController.h"
#import <LNPropertyListEditor/LNPropertyListEditor.h>

@implementation ViewController
{
	IBOutlet LNPropertyListEditor* _plistEditor;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	NSURL* propertyListURL = [[NSBundle mainBundle].bundleURL URLByAppendingPathComponent:@"Contents/Info.plist"];
	id obj = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:propertyListURL] options:0 format:nil error:NULL];
	
	_plistEditor.propertyList = obj;
}

@end
