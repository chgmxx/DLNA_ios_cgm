//
//  LGPINRemoteImageDownloaderEx.m
//  ASPhotoBrowser
//
//  Created by liaogang on 16/8/29.
//  Copyright © 2016年 liaogang. All rights reserved.
//


#import <LGPhotoBrowser/LGPINRemoteImageDownloaderEx.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <LGPhotoBrowser/UIImage+YYWebImage.h>

#if __has_include (<PINRemoteImage/PINAnimatedImage.h>)
#define PIN_ANIMATED_AVAILABLE 1
//#warning "PIN_ANIMATED_AVAILABLE 1"
#import <PINRemoteImage/PINAnimatedImage.h>
#import <PINRemoteImage/PINAlternateRepresentationProvider.h>
#else
#warning "PIN_ANIMATED_AVAILABLE 0"
#define PIN_ANIMATED_AVAILABLE 0
#endif

#import <PINRemoteImage/PINRemoteImageManager.h>
#import <PINRemoteImage/NSData+ImageDetectors.h>
#import <PINCache/PINCache.h>

#if PIN_ANIMATED_AVAILABLE

#define Print_Log 0


@interface PINAnimatedImage (LGPINRemoteImageDownloaderEx) <ASAnimatedImageProtocol>

@end

@implementation PINAnimatedImage (LGPINRemoteImageDownloaderEx)

- (void)setCoverImageReadyCallback:(void (^)(UIImage * _Nonnull))coverImageReadyCallback
{
  self.infoCompletion = coverImageReadyCallback;
}

- (void (^)(UIImage * _Nonnull))coverImageReadyCallback
{
  return self.infoCompletion;
}

- (void)setPlaybackReadyCallback:(dispatch_block_t)playbackReadyCallback
{
  self.fileReady = playbackReadyCallback;
}

- (dispatch_block_t)playbackReadyCallback
{
  return self.fileReady;
}

- (BOOL)isDataSupported:(NSData *)data
{
  return [data pin_isGIF];
}

@end
#endif

@interface ASPINRemoteImageManagerEx : PINRemoteImageManager
@end

@implementation ASPINRemoteImageManagerEx

//Share image cache with sharedImageManager image cache.
- (PINCache *)defaultImageCache
{
    PINCache *cache = [[PINRemoteImageManager sharedImageManager] cache];
    cache.diskCache.byteLimit = 400 * 1024;
    return cache;
}
@end

/// Just subclass to offset another cache for transformed iamge
@interface ASPINRemoteImageManagerExForTransformed : PINRemoteImageManager
@end

@implementation ASPINRemoteImageManagerExForTransformed

- (PINCache *)defaultImageCache
{
    PINCache *cache = [[PINCache alloc]initWithName:@"scale_image_cache"];
    cache.diskCache.byteLimit = 4000000 * 1024;
    return cache;
}

@end






@interface LGPINRemoteImageDownloaderEx () <PINRemoteImageManagerAlternateRepresentationProvider>
{
    CGSize _scaleSize;
}
@property (nonatomic) bool handleTransform;
@property (nonatomic,strong) PINRemoteImageManager *innerManager;
@property (nonatomic,strong) NSString* processorKey;
@end


@implementation LGPINRemoteImageDownloaderEx

-(void)setScaleSize:(CGSize)size
{
    NSAssert(size.width > 1, nil);
    _scaleSize = size;
}

-(void)clearMemory
{
    [self.innerManager.cache.memoryCache removeAllObjects];
}

+ (instancetype )sharedDownloader
{
  static LGPINRemoteImageDownloaderEx *sharedDownloader = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    sharedDownloader = [[LGPINRemoteImageDownloaderEx alloc] init];
      
#if PIN_ANIMATED_AVAILABLE
      // Check that Carthage users have linked both PINRemoteImage & PINCache by testing for one file each
      if (!(NSClassFromString(@"PINRemoteImageManager"))) {
          NSException *e = [NSException
                            exceptionWithName:@"FrameworkSetupException"
                            reason:@"Missing the path to the PINRemoteImage framework."
                            userInfo:nil];
          @throw e;
      }
      if (!(NSClassFromString(@"PINCache"))) {
          NSException *e = [NSException
                            exceptionWithName:@"FrameworkSetupException"
                            reason:@"Missing the path to the PINCache framework."
                            userInfo:nil];
          @throw e;
      }
      sharedDownloader.innerManager = [[ASPINRemoteImageManagerEx alloc] initWithSessionConfiguration:nil alternativeRepresentationProvider: sharedDownloader ];
#else
      sharedDownloader.innerManager = [[ASPINRemoteImageManagerEx alloc] initWithSessionConfiguration:nil];
#endif
      
  });
  return sharedDownloader;
}

+ (instancetype )sharedTransformedDownloader
{
    static LGPINRemoteImageDownloaderEx *sharedDownloader = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[LGPINRemoteImageDownloaderEx alloc] init];
        sharedDownloader.handleTransform = true;
        
#if PIN_ANIMATED_AVAILABLE
        // Check that Carthage users have linked both PINRemoteImage & PINCache by testing for one file each
        if (!(NSClassFromString(@"PINRemoteImageManager"))) {
            NSException *e = [NSException
                              exceptionWithName:@"FrameworkSetupException"
                              reason:@"Missing the path to the PINRemoteImage framework."
                              userInfo:nil];
            @throw e;
        }
        if (!(NSClassFromString(@"PINCache"))) {
            NSException *e = [NSException
                              exceptionWithName:@"FrameworkSetupException"
                              reason:@"Missing the path to the PINCache framework."
                              userInfo:nil];
            @throw e;
        }
        sharedDownloader.innerManager = [[ASPINRemoteImageManagerExForTransformed alloc] initWithSessionConfiguration:nil alternativeRepresentationProvider:sharedDownloader];
#else
        sharedDownloader.innerManager = [[ASPINRemoteImageManagerExForTransformed alloc] initWithSessionConfiguration:nil];
#endif
        
        sharedDownloader.processorKey = @"transform_image";
        
    });
    return sharedDownloader;
}




#pragma mark ASImageProtocols

#if PIN_ANIMATED_AVAILABLE
- (nullable id <ASAnimatedImageProtocol>)animatedImageWithData:(NSData *)animatedImageData
{
  return [[PINAnimatedImage alloc] initWithAnimatedImageData:animatedImageData];
}
#endif

- (id <ASImageContainerProtocol>)synchronouslyFetchedCachedImageWithURL:(NSURL *)URL;
{
#if Print_Log
    NSLog(@"request image from memory");
#endif
    
  PINRemoteImageManager *manager = self.innerManager ;
  NSString *key = [manager cacheKeyForURL:URL processorKey: _processorKey];
  PINRemoteImageManagerResult *result = [manager synchronousImageFromCacheWithCacheKey:key options:PINRemoteImageManagerDownloadOptionsSkipDecode];
#if PIN_ANIMATED_AVAILABLE
  if (result.alternativeRepresentation) {
    return result.alternativeRepresentation;
  }
#endif
    
    
#if Print_Log
    if (result.image) {
        NSLog(@"get a image from memory cache,size: %@",  NSStringFromCGSize(result.image.size) );
    }
#endif
    
    
  return result.image;
}

- (void)cachedImageWithURL:(NSURL *)URL
             callbackQueue:(dispatch_queue_t)callbackQueue
                completion:(ASImageCacherCompletion)completion
{
    // We do not check the cache here and instead check it in downloadImageWithURL to avoid checking the cache twice.
    NSString *key = [self.innerManager cacheKeyForURL:URL processorKey:_processorKey];
    
    [self.innerManager  imageFromCacheWithCacheKey:key options:PINRemoteImageManagerDownloadOptionsSkipDecode completion:^(PINRemoteImageManagerResult * _Nonnull result) {
       
    
#if Print_Log
        if (result.image) {
            NSLog(@"transform? %d, get a cached image,size: %@", _handleTransform ,  NSStringFromCGSize(result.image.size) );
        }
        else{
            NSLog(@"transform? %d,request image from disk failed",_handleTransform);
        }
#endif
        
        // If we're targeting the main queue and we're on the main thread, complete immediately.
        if (ASDisplayNodeThreadIsMain() && callbackQueue == dispatch_get_main_queue()) {
            completion(result.image);
        }
        else
            dispatch_async(callbackQueue, ^{
                completion(result.image);
            });
        
        
    }];
    
}

- (void)clearFetchedImageFromCacheWithURL:(NSURL *)URL
{
  PINRemoteImageManager *manager = self.innerManager ;
  NSString *key = [manager cacheKeyForURL:URL processorKey:_processorKey];
  [[[manager cache] memoryCache] removeObjectForKey:key];
}

- (nullable id)downloadImageWithURL:(NSURL *)URL
                      callbackQueue:(dispatch_queue_t)callbackQueue
                   downloadProgress:(ASImageDownloaderProgress)downloadProgress
                         completion:(ASImageDownloaderCompletion)completion;
{
    NSAssert( self.handleTransform ?  _scaleSize.width > 1 : 1, nil);
    
    typedef void (^CompletionBlock)(PINRemoteImageManagerResult * _Nonnull result);
    CompletionBlock _completion = ^(PINRemoteImageManagerResult * _Nonnull result){
        
#if Print_Log
        NSLog(@"transform? %d,Downloaded from network: %lu ,size: %@",_handleTransform,(unsigned long)result.resultType, NSStringFromCGSize( result.image.size) );
#endif
        
        if (ASDisplayNodeThreadIsMain() && callbackQueue == dispatch_get_main_queue()) {
#if PIN_ANIMATED_AVAILABLE
            if (result.alternativeRepresentation) {
                completion(result.alternativeRepresentation, result.error, result.UUID);
            } else {
                completion( result.image , result.error, result.UUID);
            }
#else
            completion( result.image , result.error, result.UUID);
#endif
        } else {
            

            
            dispatch_async(callbackQueue, ^{
#if PIN_ANIMATED_AVAILABLE
                if (result.alternativeRepresentation) {
                    completion(result.alternativeRepresentation, result.error, result.UUID);
                } else {
                    completion( result.image , result.error, result.UUID);
                }
#else
                completion( result.image , result.error, result.UUID);
#endif
            });
        }
 
    };
    

    
    if(_handleTransform)
    {
        return  [self.innerManager downloadImageWithURL:URL options:PINRemoteImageManagerDownloadOptionsSkipDecode processorKey:_processorKey processor:^UIImage * _Nullable(PINRemoteImageManagerResult * _Nonnull result, NSUInteger * _Nonnull cost) {
            
            UIImage *transformed =  [result.image yy_imageByResizeToSize:_scaleSize contentMode:UIViewContentModeScaleAspectFit];
//            UIImage *transformed =  [result.image yy_imageByResizeToSize:_scaleSize ];
            
            return transformed;
            
        } completion:^(PINRemoteImageManagerResult * _Nonnull result) {
            
            _completion(result);
            
        }];
    }
    else
    {
        PINRemoteImageManagerDownloadOptions options =PINRemoteImageManagerDownloadOptionsSkipDecode ;
        
        return [self.innerManager downloadImageWithURL:URL options:options progressDownload:^(int64_t completedBytes, int64_t totalBytes) {
            if (downloadProgress == nil) { return; }
            
            /// If we're targeting the main queue and we're on the main thread, call immediately.
            if (ASDisplayNodeThreadIsMain() && callbackQueue == dispatch_get_main_queue()) {
                downloadProgress(completedBytes / (CGFloat)totalBytes);
            } else {
                dispatch_async(callbackQueue, ^{
                    downloadProgress(completedBytes / (CGFloat)totalBytes);
                });
            }
        } completion:^(PINRemoteImageManagerResult * _Nonnull result) {
            /// If we're targeting the main queue and we're on the main thread, complete immediately.
#if Print_Log
//            NSLog(@"Downloaded from network,%d",result.resultType);
#endif
            _completion(result);
        }];
    }
    
        
}

- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
  if (!downloadIdentifier) {
    return;
  }
  
  ASDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");
  [self.innerManager cancelTaskWithUUID:downloadIdentifier];
}

- (void)setProgressImageBlock:(ASImageDownloaderProgressImage)progressBlock callbackQueue:(dispatch_queue_t)callbackQueue withDownloadIdentifier:(id)downloadIdentifier
{
  ASDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");
  
  if (progressBlock) {
    [self.innerManager  setProgressImageCallback:^(PINRemoteImageManagerResult * _Nonnull result) {
      dispatch_async(callbackQueue, ^{
        progressBlock(result.image, result.renderedImageQuality, result.UUID);
      });
    } ofTaskWithUUID:downloadIdentifier];
  } else {
    [self.innerManager  setProgressImageCallback:nil ofTaskWithUUID:downloadIdentifier];
  }
}

- (void)setPriority:(ASImageDownloaderPriority)priority withDownloadIdentifier:(id)downloadIdentifier
{
  ASDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");
    
#if Print_Log
    NSLog(@"set download priority: %lu",(unsigned long)priority);
#endif
    
  PINRemoteImageManagerPriority pi_priority = PINRemoteImageManagerPriorityMedium;
  switch (priority) {
    case ASImageDownloaderPriorityPreload:
      pi_priority = PINRemoteImageManagerPriorityMedium;
      break;
      
    case ASImageDownloaderPriorityImminent:
      pi_priority = PINRemoteImageManagerPriorityHigh;
      break;
      
    case ASImageDownloaderPriorityVisible:
      pi_priority = PINRemoteImageManagerPriorityVeryHigh;
      break;
  }
  [self.innerManager  setPriority:pi_priority ofTaskWithUUID:downloadIdentifier];
}

#pragma mark - PINRemoteImageManagerAlternateRepresentationProvider

- (id)alternateRepresentationWithData:(NSData *)data options:(PINRemoteImageManagerDownloadOptions)options
{
#if PIN_ANIMATED_AVAILABLE
    if ([data pin_isGIF]) {
        return data;
    }
#endif
    return nil;
}

@end
