

#import "YGPCache.h"
#import <UIKit/UIKit.h>
#import "YGPCacheMemory.h"
#import "YGPCacheDisk.h"

static NSString   *const YGPCacheDirectoryName  = @"YLCache";

static inline NSString *escapedString(NSString *key){
    
    if (![key length])return @"";
    
    CFStringRef static const charsToEscape = CFSTR(".:/");
    CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                        (__bridge CFStringRef)key,
                                                                        NULL,
                                                                        charsToEscape,
                                                                        kCFStringEncodingUTF8);
    return (__bridge_transfer NSString *)escapedString;
}

static inline NSString *unescapedString(NSString *key){
    
    if (![key length])return @"";
    
    CFStringRef unescapedString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                          (__bridge CFStringRef)key,
                                                                                          CFSTR(""),
                                                                                          kCFStringEncodingUTF8);
    return (__bridge_transfer NSString *)unescapedString;
}

@interface YGPCache()
@property (nonatomic,strong)YGPCacheMemory *cacheMemory;
@property (nonatomic,strong)YGPCacheDisk   *cacheDisk;

@end

@implementation YGPCache

+ (instancetype)sharedCache{
    
    static YGPCache *_ygp_YGPCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ygp_YGPCache = [[YGPCache alloc]init];
    });
    
    return _ygp_YGPCache;
}
- (instancetype)init{
    return [self initWithCacheDirectory:YGPCacheDirectoryName];
}

- (instancetype)initWithCacheDirectory:(NSString*)cacheDirectory{
    
    self = [super init];
    
    if (self) {
        
        _cacheDisk   = [[YGPCacheDisk alloc]initWithCacheDirectory:cacheDirectory];
        _cacheMemory = [YGPCacheMemory sharedMemory];
        
    }
    return self;
    
}

#pragma mark Data
- (void)setDataToDiskWithData:(NSData *)data forKey:(NSString *)key{
    [_cacheDisk setData:data forKey:escapedString(key)];
}

- (void)setDataToMemoryWithData:(NSData *)data forKey:(NSString *)key{
    [_cacheMemory setData:data forKey:escapedString(key)];
}

- (void)dataForKey:(NSString *)key block:(YGPCacheDataCacheObjectBlock)block{
    [_cacheDisk dataForKey:escapedString(key) block:^(NSData *data, NSString *key) {
        if (block) {
            block(data,unescapedString(key));
        }
    }];
}


#pragma mark Image
- (void)setImageToDiskWithImage:(UIImage *)image forKey:(NSString *)key{
    [self setDataToDiskWithData:UIImageJPEGRepresentation(image, 1.f) forKey:key];
}

- (void)setImageToMemoryWithImage:(UIImage *)image forKey:(NSString *)key{
    [self setDataToMemoryWithData:UIImageJPEGRepresentation(image, 1.f) forKey:key];
}

- (void)imageForKey:(NSString *)key block:(YGPCacheImageCacheObjectBlock)block{

    [_cacheDisk dataForKey:key block:^(NSData *data, NSString *key) {
        
        UIImage *image = [UIImage imageWithData:data];
        
        if (block) {
            block(image,unescapedString(key));
        }
        
    }];
}

#pragma mark Object
- (void)setObjectToDisk:(id<NSCopying>)object forKey:(NSString*)aKey{
    
    NSData *Data = [NSKeyedArchiver archivedDataWithRootObject:object];
    [self setDataToDiskWithData:Data forKey:aKey];
}

- (void)setObjectToMemory:(id<NSCopying>)object forKey:(NSString *)aKey{

    NSData *Data = [NSKeyedArchiver archivedDataWithRootObject:object];
    [self setDataToMemoryWithData:Data forKey:aKey];
}

- (void)objectForKey:(NSString *)key block:(YGPCacheObjectBlock)block{
    
    [_cacheDisk dataForKey:key block:^(NSData *data, NSString *key) {
        
        id obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        if (block) {
            block(obj,unescapedString(key));
        }
    }];
}

#pragma mark Remove

- (void)removeDiskCacheDataForKey:(NSString *)key{
    [_cacheDisk removeDataForKey:escapedString(key)];
}

- (void)removeDiskAllData{
    [_cacheDisk removeAllData];
}

- (void)removeMemoryCacheDataForKey:(NSString *)key{
    [_cacheMemory removeDataForKey:escapedString(key)];
}

- (void)removeMemoryAllData{
    [_cacheMemory removeAllData];
}

#pragma mark search

- (BOOL)isDataExistOnDiskForKey:(NSString *)key{
   return [_cacheDisk isDataExistOnDiskForKey:escapedString(key)];
}

- (BOOL)containsMemoryObjectForKey:(NSString *)key{
   return [_cacheMemory containsDataForKey:escapedString(key)];
}

- (float)diskCacheSize{
    return [_cacheDisk diskCacheSize];
}

- (NSUInteger)diskCacheFileCount{
    return [_cacheDisk diskCacheFileCount];
}

@end










