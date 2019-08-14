#import <Foundation/Foundation.h>

#import "FileSystemPermission.h"

NS_ASSUME_NONNULL_BEGIN

@interface FilePermissionModule : NSNull

- (FileSystemPermissionFlags)getPathPermissions:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
