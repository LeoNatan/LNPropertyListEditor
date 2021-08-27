//
//  LNPropertyListDataEditorPanel.h
//  LNPropertyListDataEditorPanel
//
//  Created by Leo Natan on 8/26/21.
//  Copyright © 2021 Leo Natan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LNPropertyListDataEditorPanel : NSPanel

@property (nonatomic, copy) NSData* data;

- (void)beginSheetModalForWindow:(NSWindow *)window completionHandler:(void (^)(NSModalResponse result))handler;

@end

NS_ASSUME_NONNULL_END
