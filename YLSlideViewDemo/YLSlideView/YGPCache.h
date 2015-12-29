/*
 version: 1.0
 可保存在内存或磁盘中，在获取数据时会先从内存中查找再查找磁盘。
 对内存中保存的数据做了LRU算法处理
 阿婆在移动 286677411 有问题可随时联系
 https://github.com/apozaiyidong/YGPCache
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class YGPMemoryCache;

typedef void(^YGPCacheDataCacheObjectBlock)(NSData *data ,NSString *key);
typedef void(^YGPCacheImageCacheObjectBlock)(UIImage *image ,NSString *key);

typedef void(^YGPCacheDataCacheImageBlock)(UIImage *image,NSString *key);

@interface YGPCache : NSObject

@property (nonatomic,assign)NSTimeInterval timeoutInterval;

+ (instancetype)sharedManager;
- (instancetype)initWithCacheDirectory:(NSString*)cacheDirectory;
/**
 *  stored data to disk
 *
 *  @param data           stored data
 *  @param key            stored key
 *  @param completedBlock stored complete block
 *  @param failureBlock   stored fail block
 */
- (void)setDataToDiskWithData:(NSData*)data
                       forKey:(NSString*)key;

/**
 *  stored data to memory
 *
 *  @param data stored data
 *  @param key  stored key
 */
- (void)setDataToMemoryWithData:(NSData*)data
                         forKey:(NSString*)key;

/**
 *  stored image to Disk
 *
 *  @param data
 *  @param key
 */
- (void)setImageToDiskWithImage:(UIImage*)image
                         forKey:(NSString*)key;

- (void)setImageToMemoryWithImage:(UIImage*)image
                           forKey:(NSString*)key;
/**
 *  get stored data form Disk
 *
 *  @param key         stored key
 *  @param objectBlock stored Object
 */
- (void)dataFromDiskForKey:(NSString*)key
                     block:(YGPCacheDataCacheObjectBlock)block;

- (void)dataFromMemoryForKey:(NSString*)key
                       block:(YGPCacheDataCacheObjectBlock)block;

/**
 *  get stored image form Disk
 *
 *  @param key   <#key description#>
 *  @param block <#block description#>
 */
- (void)imageFromDiskForKey:(NSString*)key
                      block:(YGPCacheImageCacheObjectBlock)block;

- (void)imageFromMemoryForKey:(NSString*)key
                        block:(YGPCacheImageCacheObjectBlock)block;
/**
 *  remove data from disk
 *
 *  @param key stored key
 */
- (void)removeDiskCacheDataForKey:(NSString*)key;
- (void)removeDiskAllData;

- (void)removeMemoryCacheDataForKey:(NSString*)key;
- (void)removeMemoryAllData;

/*
 * is cache
 */
- (BOOL)isDataExistOnDiskForKey:(NSString*)key;
- (BOOL)containsMemoryObjectForKey:(NSString*)key;

- (float)diskCacheSize;
- (NSUInteger)diskCacheFileCount;

//对象转成NSData
+ (NSData*)dataWithJSONObject:(id)object;
+ (id)JSONObjectWithData:(NSData*)data;
+ (NSData*)dataWithImageObject:(UIImage*)image;

@end

@interface YGPMemoryCache : NSObject
@property (nonatomic,assign)NSUInteger memoryCacheCountLimit;

- (void)setData:(NSData*)data forKey:(NSString*)key;
- (NSData*)objectForKey:(NSString*)key;
- (void)removeDataForKey:(NSString*)key;
- (void)removeAllData;
- (BOOL)containsDataForKey:(NSString*)key;

@end
