



#import "YGPCacheMemory.h"
#import <UIKit/UIKit.h>

#pragma mark memory cache
@interface YGPMemoryCacheNode :NSObject
@property (nonatomic,copy)   NSString       *key;
@property (nonatomic,assign) NSTimeInterval accessedTime;
@property (nonatomic,assign) NSUInteger     accessedCount;
@end

@implementation YGPMemoryCacheNode

- (instancetype)initWithKey:(NSString*)key forAccessedCount:(NSUInteger)AccessedCount{
    
    self = [super init];
    
    if (self) {
        _key               = [key copy];
        _accessedCount     = AccessedCount;
        NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
        _accessedTime      = now;
        
    }
    return self;
}
@end

static inline YGPMemoryCacheNode *memoryCacheNode(NSString *key,NSUInteger accessedCount){
    
    YGPMemoryCacheNode * cacheNode = [[YGPMemoryCacheNode alloc]initWithKey:key
                                                           forAccessedCount:accessedCount];
    
    return cacheNode;
}


static NSUInteger  const YGPCacheCacheMemoryObjLimit    = 35; //max count
static NSString   *const YGPCacheAttributeListName      = @"YGPCacheAttributeList";
static char       *const YGPCacheMemoryIOQueue          = "YGPCacheMemoryIOQueue";

@interface YGPCacheMemory ()
{
    NSMutableDictionary *_cacheData;
    NSMutableArray      *_recentlyAccessedKeys;
    NSMutableDictionary *_recentlyNode;
    NSTimeInterval       _recentlyHandleTime;
    NSUInteger           _minAccessedCount;
}

@property (nonatomic,strong) dispatch_queue_t memoryIoQueue;
@end

@implementation YGPCacheMemory

+ (instancetype)sharedMemory{
    
    static YGPCacheMemory *_ygp_YGPCacheMemory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ygp_YGPCacheMemory = [[YGPCacheMemory alloc]init];
    });
    return _ygp_YGPCacheMemory;
}

- (instancetype)init{
    
    self = [super init];
    
    if (self) {
        
        _cacheData             = [[NSMutableDictionary alloc]init];
        _recentlyNode          = [[NSMutableDictionary alloc]init];
        _recentlyAccessedKeys  = [[NSMutableArray alloc]init];
        _recentlyHandleTime    = [[NSDate date] timeIntervalSinceReferenceDate];
        _minAccessedCount      = 1;
        _memoryCacheCountLimit = YGPCacheCacheMemoryObjLimit;
        _memoryIoQueue         = dispatch_queue_create(YGPCacheMemoryIOQueue, DISPATCH_QUEUE_SERIAL);
        
        [[NSNotificationCenter defaultCenter]addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * __unused note) {
            [self removeAllData];
        }];
        
        [[NSNotificationCenter defaultCenter]addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * __unused note) {
            [self removeAllData];
        }];
        
        [[NSNotificationCenter defaultCenter]addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * __unused note) {
            [self removeAllData];
        }];
        

        
    }
    return self;
}

- (void)setData:(NSData*)data forKey:(NSString*)key{
    
    if (![key length] ||![data length]) {return;}
    
    dispatch_async(_memoryIoQueue, ^{
        
        [_cacheData setObject:data forKey:key];
        
    });
    
}

- (NSData*)objectForKey:(NSString*)key{
    
    if (![key length]) {return nil;}
    
    __block NSData *cacheData = nil;
    
    dispatch_sync(_memoryIoQueue, ^{
        
        cacheData = _cacheData[key];
        
        if (cacheData) {
            [self timeoutObjForKey:key];
        }
        
    });
    
    return cacheData;
}

- (void)removeAllData{
    
    dispatch_async(_memoryIoQueue, ^{
        
        [_cacheData            removeAllObjects];
        [_recentlyAccessedKeys removeAllObjects];
        [_recentlyNode         removeAllObjects];
    });
}

- (void)removeDataForKey:(NSString*)key{
    
    if (![key length]) {return;}
    
    dispatch_async(_memoryIoQueue, ^{
        
        [_cacheData removeObjectForKey:key];
        if ([_recentlyAccessedKeys containsObject:key]) {
            [_recentlyAccessedKeys removeObject:key];
            [_recentlyNode         removeObjectForKey:key];
        }
    });
}

- (BOOL)containsDataForKey:(NSString*)key{
    
    __block BOOL isContains = NO;
    
    dispatch_sync(_memoryIoQueue, ^{
        if (_cacheData[key]) {
            isContains = YES;
        }
    });
    
    return isContains;
}

- (void)timeoutObjForKey:(NSString*)key{
    
    /*
     
     获取一个缓存数据，就将其移动到队列的最顶端，队列内越后的数据就是调用得最少次的
     设置一个内存LIMIT 最大值，当缓存数据超过了最大值。每次有新的数据进入列队，就会讲
     列队的最后一个缓存数据移除掉。
     
     每个缓存数据都会组建成一个结构体 里面包含 （访问次数 ，访问时间）
     每隔3分钟的时候就会去调用 队列  将访问次数最小和访问时间离现在最久的数据将其出列
     
     */
    
    YGPMemoryCacheNode *node = nil;
    
    if ([_recentlyAccessedKeys containsObject:key]) {
        [_recentlyAccessedKeys removeObject:key];
        
        node = _recentlyNode[key];
        [_recentlyNode removeObjectForKey:key];
    }
    
    [_recentlyAccessedKeys insertObject:key atIndex:0];
    
    //增加内存访问的计时和时间
    NSUInteger accessedCount = 1;
    if (node)accessedCount   = node.accessedCount+1;
    
    //获取最小的访问数
    if (accessedCount < _minAccessedCount) _minAccessedCount = accessedCount;
    
    [_recentlyNode setObject:memoryCacheNode(key, accessedCount) forKey:key];
    
    //移除近期不访问
    if (_recentlyAccessedKeys.count >= YGPCacheCacheMemoryObjLimit) {
        NSString *lastObjKey = [_recentlyAccessedKeys lastObject];
        [_cacheData    removeObjectForKey:lastObjKey];
        [_recentlyNode removeObjectForKey:lastObjKey];
    }
    
    //remove timeout data
    NSTimeInterval now     = [[NSDate date] timeIntervalSinceReferenceDate];
    NSTimeInterval timeout = 60 * 5;
    
    if ((now - _recentlyHandleTime) >= timeout) {
        
        [_recentlyNode enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            YGPMemoryCacheNode *node = (YGPMemoryCacheNode*)obj;
            
            if ((now - node.accessedTime) >= timeout && node.accessedCount <= _minAccessedCount) {
                
                [_cacheData            removeObjectForKey:key];
                [_recentlyNode         removeObjectForKey:key];
                [_recentlyAccessedKeys removeObject:key];
                
            }
        }];
    }
    
    
    _recentlyHandleTime = now;
}

@end



