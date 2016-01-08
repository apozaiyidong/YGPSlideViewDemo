

#import "YGPCacheDisk.h"
#import "YGPCacheMemory.h"

static char       *const YGPCacheDiskIOQueue            = "YGPCacheDiskIOQueue";
static NSString   *const YGPCacheAttributeListName      = @"YGPCacheAttributeList";
static NSString   *const YGPCacheDirectoryName          = @"YLCache";

@interface YGPCacheDisk ()
@property (nonatomic,strong) NSFileManager    *fileManager;
@property (nonatomic,copy)   NSString         *cacheDiskPath;
@property (nonatomic,strong) dispatch_queue_t diskIoQueue;
@property (nonatomic,strong) YGPCacheMemory   *memoryCache;
@end

@implementation YGPCacheDisk

+ (instancetype)sharedDisk{
    
    static YGPCacheDisk *_ygp_YGPCacheDisk= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ygp_YGPCacheDisk = [[YGPCacheDisk alloc]init];
    });
    
    return _ygp_YGPCacheDisk;
}

- (instancetype)init{
    return [self initWithCacheDirectory:YGPCacheDirectoryName];
}

- (instancetype)initWithCacheDirectory:(NSString*)cacheDirectory{

    self = [super init];
    
    if (self) {
        [self ygp_initMethodWithCacheDirectory:cacheDirectory];
    }
    return self;
    
}

- (void)ygp_initMethodWithCacheDirectory:(NSString*)cacheDirectory{
    
    _cacheDiskPath = [[self ygp_CacheDirectory:cacheDirectory] copy];
    _diskIoQueue   = dispatch_queue_create(YGPCacheDiskIOQueue, DISPATCH_QUEUE_SERIAL);
    _memoryCache   = [YGPCacheMemory sharedMemory];
    
    [self setTimeoutInterval:60*60*24*2];
    
    [self clearTimeoutDiskFile];
}


- (NSString*)ygp_CacheDirectory:(NSString*)cacheDirectory{
    
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *ygp_cachePath = [docDir stringByAppendingPathComponent:cacheDirectory];
        
    self.fileManager = [[NSFileManager alloc]init];
    BOOL isDir       = false;
    
    if (![_fileManager fileExistsAtPath:ygp_cachePath isDirectory:&isDir]) {
        
        NSError *error = nil;
        
        BOOL res = [_fileManager createDirectoryAtPath:ygp_cachePath
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:&error];
        
        if (!res) {
            NSLog(@"创建文件目录失败 %@",error);
        }
    }
    
    return ygp_cachePath;
}

- (NSString*)ygp_filePathWithKey:(NSString*)key{
    NSString *path = [NSString stringWithFormat:@"%@/%@",_cacheDiskPath,key];
    return path;
}

#pragma mark Disk add get remove
- (void)setData:(NSData *)data forKey:(NSString *)key{
    
    if (![key length] ||![data length]) {return;}
    
    dispatch_async(self.diskIoQueue, ^{
        
        BOOL      isCacheSuccess;
        NSData   *writeData    = data;
        NSString *path         = [self ygp_filePathWithKey:key];
        isCacheSuccess  = [writeData writeToFile:path atomically:YES];
        
        [self addTimeoutListForKey:key];
        
    });
}


- (void)dataForKey:(NSString*)key
             block:(YGPCacheDataCacheObjectBlock)block{
    
    if (![key length]) {
        if (block) {
            block(nil,nil);
        }
    }
    
    dispatch_async(self.diskIoQueue, ^{
        
        NSData *cacheData = nil;
        
        // Memory cache data
        // 查看内存中
        cacheData = [_memoryCache objectForKey:key];
        
        if (cacheData) {
            if (block){
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(cacheData,key);
                });
            }
        }else{
            
            NSString *path = [self ygp_filePathWithKey:key];
            
            if ([_fileManager fileExistsAtPath:path]) {
                cacheData = [NSData dataWithContentsOfFile:path options:0 error:nil];
            }
            
            // data write the memory
            if (cacheData) {
                [_memoryCache setData:cacheData forKey:key];
            }
            
            if (block){
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(cacheData,key);
                    
                });
            }
        }
    });
}

- (void)removeDataForKey:(NSString *)key{
    
    if (![key length]) {return;}
    
    dispatch_async(self.diskIoQueue, ^{
        
        [_fileManager removeItemAtPath:key error:nil];
        [_memoryCache removeDataForKey:key];
        
    });
}

- (void)removeAllData{
    
    dispatch_async(self.diskIoQueue, ^{
        
        NSDirectoryEnumerator * fileEnumerator = [_fileManager enumeratorAtPath:_cacheDiskPath];
        
        for (NSString *fileName in fileEnumerator) {
            [_fileManager removeItemAtPath:fileName error:nil];
        }
        
    });
}

- (BOOL)isDataExistOnDiskForKey:(NSString *)key{
    
    __block BOOL isContains  = NO;
    dispatch_sync(self.diskIoQueue, ^{
        
        NSString *path = [self ygp_filePathWithKey:key];
        if ([_fileManager fileExistsAtPath:path]) {
            isContains = YES;
        }
    });
    
    return isContains;
}

#pragma mark

- (float)diskCacheSize{
    
    __block float folderSize = 0;
    
    if (![_fileManager fileExistsAtPath:_cacheDiskPath])
        return 0;
    
    dispatch_sync(self.diskIoQueue, ^{
        
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:_cacheDiskPath];
        
        for (NSString *fileName in fileEnumerator) {
            
            NSString *filePath = [_cacheDiskPath stringByAppendingPathComponent:fileName];
            folderSize += [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
            
        }
    });
    
    return folderSize / (1024.0 * 1024.0); //Mb
}

- (NSUInteger)diskCacheFileCount{
    
    __block NSUInteger fileCount = 0;
    
    dispatch_sync(self.diskIoQueue, ^{
        
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:_cacheDiskPath];
        fileCount = [[fileEnumerator allObjects] count];
        
    });
    
    return fileCount;
}

#pragma mark TimeoutList

- (NSMutableDictionary*)getTimeoutList{
    
    __block NSData *cacheListData  = nil;
    NSMutableDictionary *cacheList = nil;
    NSString * filePath = [self ygp_filePathWithKey:YGPCacheAttributeListName];
    cacheListData = [NSData dataWithContentsOfFile:filePath
                                           options:0
                                             error:nil];
    
    if (!cacheListData) {
        cacheList = [[NSMutableDictionary alloc]init];
    }else{
        cacheList = [[NSJSONSerialization JSONObjectWithData:cacheListData
                                                     options:kNilOptions
                                                       error:nil] mutableCopy];
    }
    
    return cacheList;
    
}

- (void)addTimeoutListForKey:(NSString*)key{
    
    //每次添加缓存数据的将在缓存列表中添加一个时间戳
    
    NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
    
    NSMutableDictionary *cacheList = [[NSMutableDictionary alloc]init];
    [cacheList addEntriesFromDictionary:[self getTimeoutList]];
    
    [cacheList setObject:[NSString stringWithFormat:@"%f",now] forKey:key];
    
    [self cacheTimeListForData:cacheList];
    
}

- (void)clearTimeoutDiskFile{
    
    
    NSTimeInterval now             = [[NSDate date] timeIntervalSinceReferenceDate];
    NSMutableArray *timeoutKeys    = [[NSMutableArray alloc]init];
    NSMutableDictionary *cacheList = [[NSMutableDictionary alloc]init];
    
    [cacheList addEntriesFromDictionary:[self getTimeoutList]];
    
    for (NSString *key in cacheList) {
        
        if ((now - [cacheList[key] doubleValue]) >= _timeoutInterval) {
            
            [[NSFileManager defaultManager] removeItemAtPath:[self ygp_filePathWithKey:key]
                                                       error:nil];
            [timeoutKeys addObject:key];
            
        }
    }
    
    [cacheList removeObjectsForKeys:timeoutKeys];
    [self cacheTimeListForData:cacheList];
    
}

- (void)cacheTimeListForData:(NSMutableDictionary*)dict{
    
    NSData *cacheListData = [NSJSONSerialization dataWithJSONObject:dict
                                                            options:NSJSONWritingPrettyPrinted
                                                              error:nil];
    
    [cacheListData writeToFile:[self ygp_filePathWithKey:YGPCacheAttributeListName] atomically:YES];
}

@end
