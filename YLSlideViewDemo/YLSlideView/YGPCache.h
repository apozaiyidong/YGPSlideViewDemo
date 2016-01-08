/*
 version: 1.0
 可保存在内存或磁盘中，在获取数据时会先从内存中查找再查找磁盘。
 对内存中保存的数据做了LRU算法处理

 https://github.com/apozaiyidong/YGPCache
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class YGPMemoryCache;

typedef void(^YGPCacheDataCacheObjectBlock)(NSData *data ,NSString *key);
typedef void(^YGPCacheImageCacheObjectBlock)(UIImage *image ,NSString *key);

typedef void(^YGPCacheObjectBlock)(id object,NSString *key);

@interface YGPCache : NSObject

@property (nonatomic,assign)NSTimeInterval timeoutInterval;

+ (instancetype)sharedCache;
- (instancetype)initWithCacheDirectory:(NSString*)cacheDirectory;

#pragma mark save get
- (void)setDataToDiskWithData:(NSData*)data forKey:(NSString*)key;
- (void)setDataToMemoryWithData:(NSData*)data forKey:(NSString*)key;

- (void)dataForKey:(NSString*)key block:(YGPCacheDataCacheObjectBlock)block;


#pragma mark Image
- (void)setImageToDiskWithImage:(UIImage*)image forKey:(NSString*)key;
- (void)setImageToMemoryWithImage:(UIImage*)image forKey:(NSString*)key;

- (void)imageForKey:(NSString*)key block:(YGPCacheImageCacheObjectBlock)block;

#pragma mark Object

- (void)setObjectToDisk:(id<NSCopying>)object forKey:(NSString*)aKey;
- (void)setObjectToMemory:(id<NSCopying>)object forKey:(NSString*)aKey;

- (void)objectForKey:(NSString*)key block:(YGPCacheObjectBlock)block;

#pragma mark Remove
- (void)removeDiskCacheDataForKey:(NSString*)key;
- (void)removeDiskAllData;

- (void)removeMemoryCacheDataForKey:(NSString*)key;
- (void)removeMemoryAllData;


- (BOOL)isDataExistOnDiskForKey:(NSString*)key;
- (BOOL)containsMemoryObjectForKey:(NSString*)key;

- (float)diskCacheSize;
- (NSUInteger)diskCacheFileCount;

@end


