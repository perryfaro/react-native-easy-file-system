// Copyright 2015-present 650 Industries. All rights reserved.
#import "FilePermissionModule.h"
#import <Foundation/Foundation.h>
#import "EasyFileSystem.h"

@interface FilePermissionModule ()

@end

@implementation FilePermissionModule

- (FileSystemPermissionFlags)getPathPermissions:(NSString *)path
{
    FileSystemPermissionFlags permissionsForInternalDirectories = [self getInternalPathPermissions:path];
    if (permissionsForInternalDirectories != FileSystemPermissionNone) {
        return permissionsForInternalDirectories;
    } else {
        return [self getExternalPathPermissions:path];
    }
}

- (FileSystemPermissionFlags)getInternalPathPermissions:(NSString *)path
{
    NSString *cachesDirectory = [[EasyFileSystem alloc] returnDirectoryPath:@"cache"];
    NSString *documentDirectory = [[EasyFileSystem alloc] returnDirectoryPath:@"document"];
    
    NSArray<NSString *> *scopedDirs = @[cachesDirectory, documentDirectory];
    NSString *standardizedPath = [path stringByStandardizingPath];
    for (NSString *scopedDirectory in scopedDirs) {
        if ([standardizedPath hasPrefix:[scopedDirectory stringByAppendingString:@"/"]] ||
            [standardizedPath isEqualToString:scopedDirectory]) {
            
            return FileSystemPermissionRead | FileSystemPermissionWrite;
        }
    }
    
    return FileSystemPermissionNone;
}

- (FileSystemPermissionFlags)getExternalPathPermissions:(NSString *)path
{
    FileSystemPermissionFlags filePermissions = FileSystemPermissionNone;
    if ([[NSFileManager defaultManager] isReadableFileAtPath:path]) {
        filePermissions |= FileSystemPermissionRead;
    }
    
    if ([[NSFileManager defaultManager] isWritableFileAtPath:path]) {
        filePermissions |= FileSystemPermissionWrite;
    }
    
    return filePermissions;
}

@end
