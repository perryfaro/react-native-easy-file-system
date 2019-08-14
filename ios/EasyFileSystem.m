#import "EasyFileSystem.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTUtils.h>

#import "FileSystemPermission.h"
#import "FilePermissionModule.h"


@interface EasyFileSystem ()

@property (nonatomic, strong) NSString *documentDirectory;
@property (nonatomic, strong) NSString *cachesDirectory;
@property (nonatomic, strong) NSString *bundleDirectory;

@end

@implementation NSData (EXFileSystem)

- (NSString *)md5String
{
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG) self.length, digest);
    NSMutableString *md5 = [NSMutableString stringWithCapacity:2 * CC_MD5_DIGEST_LENGTH];
    for (unsigned int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
        [md5 appendFormat:@"%02x", digest[i]];
    }
    return md5;
}

@end


@implementation EasyFileSystem

#pragma mark - Public utils

- (NSString *)returnDirectoryPath:(NSString *) directory
{
    if ([directory isEqual: @"cache"]) {
        return [self getPathForDirectory:NSCachesDirectory];
    } else if ([directory isEqual: @"document"]) {
        return [self getPathForDirectory:NSDocumentDirectory];
    }
    return [self getPathForDirectory:NSDocumentDirectory];
}


- (FileSystemPermissionFlags)_permissionsForPath:(NSString *)path
{
    return [[FilePermissionModule alloc] getPathPermissions:(NSString *)path];
}

- (FileSystemPermissionFlags)permissionsForURI:(NSURL *)uri
{
    NSArray *validSchemas = @[
                              @"assets-library",
                              @"http",
                              @"https",
                              ];
    if ([validSchemas containsObject:uri.scheme]) {
        return FileSystemPermissionRead;
    }
    
    if ([uri.scheme isEqualToString:@"file"]) {
        return [self _permissionsForPath:uri.path];
    }
    return FileSystemPermissionNone;
}

- (BOOL)checkIfFileDirExists:(NSString *)path
{
    NSString *dir = [path stringByDeletingLastPathComponent];
    return [[NSFileManager defaultManager] fileExistsAtPath:dir];
}

#pragma mark - Class methods

- (BOOL)ensureDirExistsWithPath:(NSString *)path
{
    return [EasyFileSystem ensureDirExistsWithPath:path];
}

+ (BOOL)ensureDirExistsWithPath:(NSString *)path
{
    BOOL isDir = NO;
    NSError *error;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    if (!(exists && isDir)) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)generatePathInDirectory:(NSString *)directory withExtension:(NSString *)extension
{
    return [EasyFileSystem generatePathInDirectory:directory withExtension:extension];
}


+ (NSString *)generatePathInDirectory:(NSString *)directory withExtension:(NSString *)extension
{
    NSString *fileName = [[[NSUUID UUID] UUIDString] stringByAppendingString:extension];
    [EasyFileSystem ensureDirExistsWithPath:directory];
    return [directory stringByAppendingPathComponent:fileName];
}

- (NSString *)getPathForDirectory:(int)directory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}


RCT_EXPORT_MODULE()

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXPORT_METHOD(downloadAsync:(NSString *)uriString
                    withLocalURI:(NSString *)localUriString
                    withOptions:(NSDictionary *)options
                    resolver:(RCTPromiseResolveBlock)resolve
                    rejecter:(RCTPromiseRejectBlock)reject)
{
  NSURL *url = [NSURL URLWithString:uriString];
  NSURL *localUri = [NSURL URLWithString:localUriString];
  if (!([self checkIfFileDirExists:localUri.path])) {
    reject(@"E_FILESYSTEM_WRONG_DESTINATION",
           [NSString stringWithFormat:@"Directory for %@ doesn't exist.", localUriString],
           nil);
    return;
  }
  
  /**
   * @todo fix this check with the following statement: !([self permissionsForURI:localUri] & FileSystemPermissionWrite)
   */
  if (!(FileSystemPermissionWrite)) {
    reject(@"E_FILESYSTEM_PERMISSIONS",
           [NSString stringWithFormat:@"File '%@' isn't writable.", localUri],
           nil);
    return;
  }
  NSString *path = localUri.path;
  
  NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
  sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
  NSDictionary *headerDict = (NSDictionary *) [options objectForKey:@"headers"];
  if (headerDict != nil) {
    sessionConfiguration.HTTPAdditionalHeaders = headerDict;
  }
  sessionConfiguration.URLCache = nil;
  NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
  NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
      reject(@"E_DOWNLOAD_FAILED",
             [NSString stringWithFormat:@"Could not download from '%@'", url],
             error);
      return;
    }
    [data writeToFile:path atomically:YES];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"uri"] = [NSURL fileURLWithPath:path].absoluteString;
    if (options[@"md5"]) {
      result[@"md5"] = [data md5String];
    }
    result[@"status"] = @([httpResponse statusCode]);
    result[@"headers"] = [httpResponse allHeaderFields];
    resolve(result);
  }];
  [task resume];
}

- (NSDictionary *)constantsToExport
{
    return @{
             @"documentDirectory": [self getPathForDirectory:NSDocumentDirectory],
             @"cacheDirectory": [self getPathForDirectory:NSCachesDirectory]
             };
}

@end
