#import <Foundation/Foundation.h>
#import <HexFiend/HFByteThemeColor.h>

@interface HFByteTheme : NSObject

@property (readonly) struct HFByteThemeColor* darkColorTable;
@property (readonly) struct HFByteThemeColor* lightColorTable;

@end
