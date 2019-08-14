#import <Foundation/Foundation.h>

typedef NS_OPTIONS(unsigned int, FileSystemPermissionFlags) {
    FileSystemPermissionNone = 0,
    FileSystemPermissionRead = 1 << 1,
    FileSystemPermissionWrite = 1 << 2,
};
