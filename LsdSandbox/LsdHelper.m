#import "LsdHelper.h"
#include "LsdExploit.h"

extern int lsd_acquire_sandbox_extension(void);

@implementation LsdHelper

+ (void)acquirePermissionWithCompletion:(void (^)(BOOL success, NSString *log))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Build a log buffer
        NSMutableString *logBuilder = [NSMutableString string];
        
        // Redirect stdout to a pipe for log capture
        int pipe_fds[2];
        pipe(pipe_fds);
        int saved_stdout = dup(STDOUT_FILENO);
        dup2(pipe_fds[1], STDOUT_FILENO);
        close(pipe_fds[1]);
        
        int result = lsd_acquire_sandbox_extension();
        
        // Restore stdout, read captured log
        dup2(saved_stdout, STDOUT_FILENO);
        close(saved_stdout);
        
        char buf[4096];
        ssize_t n;
        while ((n = read(pipe_fds[0], buf, sizeof(buf) - 1)) > 0) {
            buf[n] = '\0';
            [logBuilder appendString:[NSString stringWithUTF8String:buf]];
        }
        close(pipe_fds[0]);
        
        // Also try to chmod the CarrierBundles directory tree
        if (result == 0) {
            // chmod 0777 on all carrier bundle paths
            NSArray *paths = @[
                @"/var/mobile/Library/CarrierBundles",
                @"/var/mobile/Library/CarrierBundles/Library",
                @"/var/mobile/Library/CarrierBundles/Overlay",
                @"/var/mobile/Library/CarrierBundles/BundleLinks",
                @"/var/mobile/Library/CarrierBundles/QPE",
                @"/var/mobile/Library/CarrierBundles/Library/Preferences",
            ];
            for (NSString *path in paths) {
                chmod([path UTF8String], 0777);
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result == 0, logBuilder);
        });
    });
}

@end