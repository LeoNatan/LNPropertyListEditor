//
//  LNPropertyListDataEditorPanel.m
//  LNPropertyListDataEditorPanel
//
//  Created by Leo Natan on 8/26/21.
//  Copyright © 2021 Leo Natan. All rights reserved.
//

#import "LNPropertyListDataEditorPanel.h"
#import <HexFiend/HexFiend.h>

@interface _LNPropertyListDataEditorTextDividerRepresenter : HFRepresenter @end

@implementation _LNPropertyListDataEditorTextDividerRepresenter

- (NSView *)createView {
	NSBox* separator = [NSBox new];
	separator.boxType = NSBoxSeparator;
	separator.autoresizingMask = NSViewHeightSizable;

	return separator;
}

- (CGFloat)minimumViewWidthForBytesPerLine:(NSUInteger)bytesPerLine {
	USE(bytesPerLine);
	return 1;
}

+ (NSPoint)defaultLayoutPosition {
	return NSMakePoint(2, 0);
}

@end

@interface LNPropertyListDataEditorPanel () <NSWindowDelegate, HFTextViewDelegate>

@end

@implementation LNPropertyListDataEditorPanel
{
	HFTextView* _hexTextView;
}

- (void)setData:(NSData *)data
{
	_data = [data copy];
	
	[self _reloadHexTextField];
}

- (void)_reloadHexTextField
{
	_hexTextView.data = _data;
	
	[self _updateWindowSizeToContent];
	
	[_hexTextView.layoutRepresenter performLayout];
	[self.undoManager removeAllActions];
}

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
		[self setFrame:NSMakeRect(0, 0, 900, 550) display:NO];
		[self center];
		self.styleMask |= NSWindowStyleMaskResizable;
		self.delegate = self;
		self.minSize = NSMakeSize(400, 300);
		
		_hexTextView = [[HFTextView alloc] initWithFrame:self.contentView.bounds];
		_hexTextView.controller.bytesPerColumn = 4;
		_hexTextView.delegate = self;
		
		HFLineCountingRepresenter* lineCountingRepresenter = [HFLineCountingRepresenter new];
		lineCountingRepresenter.lineNumberFormat = HFLineNumberFormatHexadecimal;
//		HFStatusBarRepresenter* statusBarRepresenter = [HFStatusBarRepresenter new];
//		statusBarRepresenter.statusMode = HFStatusModeDecimal;
		_LNPropertyListDataEditorTextDividerRepresenter* textDivider = [_LNPropertyListDataEditorTextDividerRepresenter new];
		
		_hexTextView.layoutRepresenter.maximizesBytesPerLine = YES;
		[_hexTextView.layoutRepresenter addRepresenter:lineCountingRepresenter];
		[_hexTextView.layoutRepresenter addRepresenter:textDivider];
//		[_hexTextView.layoutRepresenter addRepresenter:statusBarRepresenter];
		[_hexTextView.controller addRepresenter:lineCountingRepresenter];
//		[_hexTextView.controller addRepresenter:statusBarRepresenter];
		_hexTextView.controller.font = [NSFont userFixedPitchFontOfSize:0];
		
		_hexTextView.controller.undoManager = self.undoManager;
		
		_hexTextView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:_hexTextView];
		
		NSButton* OKButton = [NSButton buttonWithTitle:@"Save" target:self action:@selector(_save:)];
		OKButton.keyEquivalent = [NSString stringWithFormat:@"\r"];
		NSButton* cancelButton = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(_cancel:)];
		cancelButton.keyEquivalent = [NSString stringWithFormat:@"%C", 0x1b];
		
		NSStackView* controlButtonsStackView = [NSStackView stackViewWithViews:@[cancelButton, OKButton]];
		controlButtonsStackView.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self.contentView addSubview:controlButtonsStackView];
		
		NSBox* backgroundBox = [NSBox new];
		backgroundBox.translatesAutoresizingMaskIntoConstraints = NO;
		backgroundBox.boxType = NSBoxCustom;
		backgroundBox.borderColor = NSColor.clearColor;
		backgroundBox.fillColor = NSColor.windowBackgroundColor;
		
		NSBox* separator = [NSBox new];
		separator.translatesAutoresizingMaskIntoConstraints = NO;
		separator.boxType = NSBoxSeparator;
		
		[self.contentView addSubview:backgroundBox positioned:NSWindowBelow relativeTo:nil];
		[self.contentView addSubview:separator positioned:NSWindowAbove relativeTo:nil];
		
		[NSLayoutConstraint activateConstraints:@[
			[self.contentView.topAnchor constraintEqualToAnchor:_hexTextView.topAnchor],
			[self.contentView.leadingAnchor constraintEqualToAnchor:_hexTextView.leadingAnchor],
			[self.contentView.trailingAnchor constraintEqualToAnchor:_hexTextView.trailingAnchor],
			[_hexTextView.bottomAnchor constraintEqualToAnchor:controlButtonsStackView.topAnchor constant:-20],
			
			[self.contentView.trailingAnchor constraintEqualToAnchor:controlButtonsStackView.trailingAnchor constant:20],
			[self.contentView.bottomAnchor constraintEqualToAnchor:controlButtonsStackView.bottomAnchor constant:20],
			
			[OKButton.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],
			
			[self.contentView.leadingAnchor constraintEqualToAnchor:backgroundBox.leadingAnchor],
			[self.contentView.trailingAnchor constraintEqualToAnchor:backgroundBox.trailingAnchor],
			[self.contentView.bottomAnchor constraintEqualToAnchor:backgroundBox.bottomAnchor],
			[controlButtonsStackView.topAnchor constraintEqualToAnchor:backgroundBox.topAnchor constant:20],
			
			[self.contentView.leadingAnchor constraintEqualToAnchor:separator.leadingAnchor],
			[self.contentView.trailingAnchor constraintEqualToAnchor:separator.trailingAnchor],
			[controlButtonsStackView.topAnchor constraintEqualToAnchor:separator.topAnchor constant:20],
		]];
		
		[_hexTextView.layoutRepresenter performLayout];
		
		NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
		[center addObserver:self selector:@selector(_updateWindowSizeToContent) name:HFLineCountingRepresenterMinimumViewWidthChanged object:lineCountingRepresenter];
	}
	
	return self;
}

- (void)_save:(id)sender
{
	_data = [_hexTextView.data copy];
	
	[self.sheetParent endSheet:self returnCode:NSModalResponseOK];
}

- (void)_cancel:(id)sender
{
	[self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
}

- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(void (^)(NSModalResponse))handler
{
//	[self makeKeyAndOrderFront:nil];
	
	[window beginCriticalSheet:self completionHandler:^(NSModalResponse returnCode) {
		handler(returnCode);
	}];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
	if(_hexTextView.layoutRepresenter == nil)
	{
		return frameSize;
	}
	
	return [self minimumWindowFrameSizeForProposedSize:frameSize];
}

- (NSSize)minimumWindowFrameSizeForProposedSize:(NSSize)frameSize
{
	NSSize proposedSizeInLayoutCoordinates = [_hexTextView convertSize:frameSize fromView:nil];
	CGFloat resultingWidthInLayoutCoordinates = [_hexTextView.layoutRepresenter minimumViewWidthForLayoutInProposedWidth:proposedSizeInLayoutCoordinates.width];
	NSSize resultSize = [_hexTextView convertSize:NSMakeSize(resultingWidthInLayoutCoordinates, proposedSizeInLayoutCoordinates.height) toView:nil];
	return resultSize;
}

- (void)_updateWindowSizeToContent
{
	NSRect windowFrame = self.frame;
	CGFloat minViewWidth = [_hexTextView.layoutRepresenter minimumViewWidthForBytesPerLine:_hexTextView.controller.bytesPerLine];
	CGFloat minWindowWidth = [_hexTextView convertSize:NSMakeSize(minViewWidth, 1) toView:nil].width;
	windowFrame.size.width = minWindowWidth;
	[self setFrame:windowFrame display:YES];
}

#pragma mark HFTextViewDelegate

- (void)hexTextView:(HFTextView *)view didChangeProperties:(HFControllerPropertyBits)properties
{
	
}

@end
