#import "LsdHelper.h"
#include "LsdExploit.h"
#include <unistd.h>
#include <sys/stat.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>

@implementation LsdHelper

+ (void)acquirePermissionWithCompletion:(void (^)(BOOL success, NSString *log))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableString *logBuilder = [NSMutableString string];
        [logBuilder appendString:@"[开始] 初始化 lsd 沙箱权限获取...\n"];

        [logBuilder appendString:@"[LockIPCC] 正在启动 LockIPCC 应用...\n"];

        Class LSAppWorkspace = NSClassFromString(@"LSApplicationWorkspace");
        if (LSAppWorkspace) {
            id workspace = ((id (*)(id, SEL))objc_msgSend)((id)LSAppWorkspace, sel_registerName("defaultWorkspace"));
            SEL openSel = sel_registerName("openApplicationWithBundleID:");
            BOOL opened = ((BOOL (*)(id, SEL, NSString *))objc_msgSend)(workspace, openSel, @"com.lock.ipcc2026");
            if (opened) {
                [logBuilder appendString:@"[LockIPCC] 已启动，等待 2 秒...\n"];
            } else {
                [logBuilder appendString:@"[LockIPCC] LSApplicationWorkspace 启动失败，尝试直接打开...\n"];
            }
        } else {
            [logBuilder appendString:@"[LockIPCC] LSApplicationWorkspace 不可用，尝试 URL scheme...\n"];
            NSURL *url = [NSURL URLWithString:@"com.lock.ipcc2026://"];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
        sleep(2);

        int pipe_fds[2];
        pipe(pipe_fds);
        int saved_stdout = dup(STDOUT_FILENO);
        dup2(pipe_fds[1], STDOUT_FILENO);
        close(pipe_fds[1]);

        int result = lsd_acquire_sandbox_extension();

        fflush(stdout);
        dup2(saved_stdout, STDOUT_FILENO);
        close(saved_stdout);

        char buf[4096];
        ssize_t n;
        while ((n = read(pipe_fds[0], buf, sizeof(buf) - 1)) > 0) {
            buf[n] = '\0';
            [logBuilder appendString:[NSString stringWithUTF8String:buf]];
        }
        close(pipe_fds[0]);

        if (result == 0) {
            [logBuilder appendString:@"[成功] 沙箱权限已获取，正在设置目录权限...\n"];

            NSArray *paths = @[
                @"/var/mobile/Library/CarrierBundles",
                @"/var/mobile/Library/CarrierBundles/Library",
                @"/var/mobile/Library/CarrierBundles/Overlay",
                @"/var/mobile/Library/CarrierBundles/BundleLinks",
                @"/var/mobile/Library/CarrierBundles/QPE",
                @"/var/mobile/Library/CarrierBundles/Library/Preferences",
            ];
            for (NSString *path in paths) {
                int r = chmod([path UTF8String], 0777);
                if (r == 0) {
                    [logBuilder appendFormat:@"  chmod 0777 ok: %@\n", path];
                } else {
                    [logBuilder appendFormat:@"  chmod FAILED (%d): %@\n", r, path];
                }
            }
            [logBuilder appendString:@"[完成] 所有操作已完成\n"];
        } else {
            if (logBuilder.length < 50) {
                [logBuilder appendString:@"[错误] 未知错误 - 无详细日志\n"];
            }
            [logBuilder appendString:@"[失败] 权限获取失败\n"];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result == 0, logBuilder);
        });
    });
}

@end