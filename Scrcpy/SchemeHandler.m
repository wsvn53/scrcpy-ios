//
//  SchemeHandler.m
//  SchemeHandler
//
//  Created by Ethan on 2021/9/11.
//

#import "SchemeHandler.h"
#import "ScrcpyParams.h"

@implementation SchemeHandler

+(void)URLToScrcpyParams:(NSURL *)url {
    ScrcpyParams.sharedParams.sshServer = url.host;
    ScrcpyParams.sharedParams.sshPort = url.port ? url.port.stringValue:@"22";
    ScrcpyParams.sharedParams.sshUser = url.user;
    
    // Password required base64 decode
    NSString *base64Pass = [url.password stringByRemovingPercentEncoding];
    NSData *passwordData = [[NSData alloc] initWithBase64EncodedString:base64Pass options:0];
    NSString *password = [[NSString alloc] initWithData:passwordData encoding:(NSUTF8StringEncoding)];
    ScrcpyParams.sharedParams.sshPassword = password;
    
    NSURLComponents *comps = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSMutableDictionary *queryDicts = [NSMutableDictionary new];
    for (NSURLQueryItem *item in comps.queryItems) {
        NSLog(@"Query: %@", item);
        queryDicts[item.name] = item.value;
    }
    
    ScrcpyParams.sharedParams.adbSerial = queryDicts[@"adbSerial"];
    ScrcpyParams.sharedParams.maxSize = queryDicts[@"maxSize"];
    ScrcpyParams.sharedParams.bitRate = queryDicts[@"bitRate"];
    ScrcpyParams.sharedParams.forceAdbForward = queryDicts[@"adbForward"];
}

@end
