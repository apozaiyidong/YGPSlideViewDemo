

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^YGPCacheDataCacheObjectBlock)(NSData *data ,NSString *key);
typedef void(^YGPCacheImageCacheObjectBlock)(UIImage *image ,NSString *key);
typedef void(^YGPCacheDataCacheImageBlock)(UIImage *image,NSString *key);

@interface YGPCacheDisk : NSObject
@property (nonatomic,assign)NSTimeInterval timeoutInterval;

+ (instancetype)sharedDisk;
- (instancetype)initWithCacheDirectory:(NSString*)cacheDirectory;

- (void)setData:(NSData*)data forKey:(NSString*)key;

- (void)dataForKey:(NSString*)key
             block:(YGPCacheDataCacheObjectBlock)block;

- (void)removeDataForKey:(NSString *)key;

- (void)removeAllData;

- (BOOL)isDataExistOnDiskForKey:(NSString *)key;

- (float)diskCacheSize;

- (NSUInteger)diskCacheFileCount;
@end
