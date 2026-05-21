// LsdHelper.m
// ObjC bridge wrapper for the C lsd exploit layer.

#import "LsdHelper.h"
#import "LsdExploit.h"
#import <sys/stat.h>

@implementation LsdHelper

+ (void)acquirePermissionWithCompletion:(void (^)(BOOL success, NSString *log))completion {
    if (!completion) return;
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableString *log = [NSMutableString string];
        
        [log appendString:@"[日志开始] 开始获取 lsd 沙箱权限...\n"];
        [log appendFormat:@"[信息] 目标进程: lsd\n"];
        [log appendFormat:@"[信息] 沙箱路径: /var/mobile\n"];
        [log appendFormat:@"[信息] 权限类型: com.apple.app-sandbox.read-write\n"];
        [log appendString:@"[信息] 正在初始化内核漏洞利用...\n"];
        
        int result = lsd_acquire_sandbox_extension();
        
        if (result == 0) {
            [log appendString:@"[成功] lsd 沙箱权限获取成功!\n"];
            [log appendString:@"[成功] 现在可以读写 /var/mobile 目录\n"];
        } else {
            [log appendFormat:@"[失败] lsd 沙箱权限获取失败 (错误码: %d)\n", result];
            [log appendString:@"[失败] 请检查:\n"];
            [log appendString:@"  - 设备是否已越狱\n"];
            [log appendString:@"  - libxpf.dylib / libchoma.dylib 是否存在\n"];
            [log appendString:@"  - lsd 进程是否正在运行\n"];
        }
        
        [log appendString:@"[日志结束]\n"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result == 0, log);
        });
    });
}

+ (int)remoteChmodPath:(NSString *)path mode:(mode_t)mode {
    return chmod([path UTF8String], mode);
}

@end