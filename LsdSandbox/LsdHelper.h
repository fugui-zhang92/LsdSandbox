// LsdHelper.h
// Bridge between Swift and the C exploit layer.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LsdHelper : NSObject

/// Acquire lsd sandbox permission. Calls the C implementation.
/// @param completion Called on the main thread with a success flag and a log message.
+ (void)acquirePermissionWithCompletion:(void (^)(BOOL success, NSString *log))completion;

/// Remote chmod – execute chmod using kernel exploit privilege level.
/// @param path Absolute file path.
/// @param mode POSIX mode (e.g. 0777).
+ (int)remoteChmodPath:(NSString *)path mode:(mode_t)mode;

@end

NS_ASSUME_NONNULL_END