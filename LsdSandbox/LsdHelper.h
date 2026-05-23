#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LsdHelper : NSObject
+ (void)acquirePermissionWithCompletion:(void (^)(BOOL success, NSString *log))completion;
@end

NS_ASSUME_NONNULL_END