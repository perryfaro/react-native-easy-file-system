#import <React/RCTBridgeModule.h>
#import <Foundation/Foundation.h>

@interface EasyFileSystem : NSObject <RCTBridgeModule>

@property (nonatomic, readonly) NSString *documentDirectory;
@property (nonatomic, readonly) NSString *cachesDirectory;
@property (nonatomic, readonly) NSString *bundleDirectory;

- (BOOL)ensureDirExistsWithPath:(NSString *)path;
- (NSString *)generatePathInDirectory:(NSString *)directory withExtension:(NSString *)extension;

- (NSString *)returnDirectoryPath:(NSString *) directory;

@end

@interface NSData (EasyFileSystem)

- (NSString *)md5String;

@end
