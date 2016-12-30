//
//  CellDataA.m
//  Genie_Main
//
//  Created by liaogang on 16/7/21.
//  Copyright © 2016年 netgear. All rights reserved.
//

#import "CellDataA.h"
#import "CellDataB.h"
#import "constFunctions.h"
#import "ipTool.h"
#import "MAAssert.h"
#import <Platinum/Platinum.h>
#import "PltMicroMediaController.h"


PLT_MediaItemResource* findResourceInMyNetwork(PLT_MediaObject *data);
NSString *uriFromDLNAItem(PLT_MediaObject *data);

NSString *mimeTypeFromDLNAItem(PLT_MediaObject *data);
NSString *mimeTypeFromDLNAItem(CellDataA *cell);
NSString *uriFromDLNAItem(PLT_MediaObject *data);
PLT_MediaObjectReference duplicateMediaObject(PLT_MediaObject *media);

@interface CellDataA ()
{
    bool loaded;
    int childCount;
    PLT_MediaObjectReference _inner;
}
@end

@implementation CellDataA

-(NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@,%d,%@,%@", _title,_type,_detail,_imageURL ];
}

-(instancetype)initWithMediaObjectRf:(PLT_MediaObjectReference)media
{
    self = [super init];
    if ( self ) {
        
        _inner = media;
    }
    
    return  self;
}


-(instancetype)initWithMediaObject:(PLT_MediaObject*)media
{
   return [self initWithMediaObjectRf: duplicateMediaObject(media) ];
}

-(NSString*)getObjectID
{
    return  [NSString stringWithUTF8String: _inner->m_ObjectID];
}

-(NSInteger)getFolderChildCount
{
    [self loadData];
    return childCount;
}

-(NSString*)getTitle
{
    [self loadData];
    return _title;
}

-(MediaType)getType
{
    [self loadData];
    return _type;
}

-(NSString*)getDetail
{
    [self loadData];
    return _detail;
}

-(NSURL*)getImageURL
{
    [self loadData];
    return _imageURL;
}

-(UIImage*)getPlaceHolder
{
    [self loadData];
    return _placeHolder;
}

-(void)loadData
{
    if (loaded == false)
    {
        loaded = true;
        
        PLT_MediaObjectReference data = _inner;
        
        
        _title = [NSString stringWithUTF8String: data->m_Title];
        
        if (data->IsContainer())
        {
            _type = Folder;
            _placeHolder =[UIImage imageNamed:@"folder"];
            
            PLT_MediaObject *c = &(*data);
            PLT_MediaContainer *container = (PLT_MediaContainer *)c;
            
            auto childCount_ =   container->m_ChildrenCount;
            
            if (childCount_ != -1)
                _detail = [NSString stringWithFormat: NSLocalizedString(@"%d items",nl) , childCount_ ];
        }
        else
        {
            if (data->m_ObjectClass.type.CompareN(szObjectClassTypeImage,(NPT_Size)strlen(szObjectClassTypeImage),true) == 0 )
            {
                _type = Photo;
                
                _placeHolder = [UIImage imageNamed:@"photoplaceholder"];
                
                if (data->m_Resources.GetItemCount() > 0) {
                    auto beg = data->m_Resources.GetFirstItem();
                    _imageURL = [NSURL URLWithString:[NSString stringWithUTF8String: beg->m_Uri]];
                }
                
            }
            else if( data->m_ObjectClass.type.Compare(szObjectClassTypeVideo,true) == 0)
            {
                _type = Video;
                
                _placeHolder = [UIImage imageNamed:@"video"];
                
                if (data->m_Resources.GetItemCount() > 0) {
                    auto beg = data->m_Resources.GetFirstItem();
                    
                    if (beg->m_Size != -1)
                        _detail= uintSizeDescription( beg->m_Size );
                }
                
                
            }
            else if( data->m_ObjectClass.type.Compare(szObjectClassTypeAudio,true) == 0 || data->m_ObjectClass.type.Compare(szObjectClassTypeAudio,true) == 0 )
            {
                _type = Music;
                
                _placeHolder = [UIImage imageNamed:@"music"];
                
                // get artist
                auto artists = data->m_People.artists;
                if (artists.GetItemCount() > 0) {
                    auto beg = artists.GetFirstItem();
                    PLT_PersonRole role = *beg;
                    _artist = [NSString stringWithUTF8String: role.name];
                }
                
                // get album info.
                _album = [NSString stringWithUTF8String:data->m_Affiliation.album];
                
                if (_artist.length == 0) {
                    _artist = @"";
                }
                if (_album.length == 0) {
                    _album = @"";
                }
                
                _subTitle = [NSString stringWithFormat:@"%@ %@",_artist,_album];
                
                
                
                // get album art icon uri
                auto album_arts = data->m_ExtraInfo.album_arts;
                int count = album_arts.GetItemCount();
                if (count > 0) {
                    auto beg = album_arts.GetFirstItem();
                    PLT_AlbumArtInfo album_art = *beg;
                    _imageURL = [NSURL URLWithString: [NSString stringWithUTF8String:album_art.uri] ];
                }
                
                

                
                if (data->m_Resources.GetItemCount() > 0) {
                    auto beg = data->m_Resources.GetFirstItem();
                    auto duration = beg->m_Duration;
                    if (duration != -1)
                        _detail = secondDescription (duration );
                    else
                    {
                        if (beg->m_Size != -1)
                            _detail = uintSizeDescription( beg->m_Size );
                    }
                    

                }
                
            }
            else
            {
                bool rmvb = false;
                
                // Tread `rmvb` as video.
                for (int i = 0; i < data->m_Resources.GetItemCount(); i++) {
                    PLT_MediaItemResource *r = data->m_Resources.GetItem(i);
                    if (r) // check the array item if is empty value even item count > 0. Is a bug here.
                    {
                        NPT_String contentType = r->m_ProtocolInfo.GetContentType();
                        if (contentType.Compare("application/vnd.rn-realmedia-vbr",true) == 0) {
                            rmvb = true;
                            break;
                        }
                    }
                }
            
                
                if (rmvb) {
                    _type = Video;
                    _placeHolder = [UIImage imageNamed:@"video"];
                    
                    if (data->m_Resources.GetItemCount() > 0) {
                        auto beg = data->m_Resources.GetFirstItem();
                        _imageURL = [NSURL URLWithString:[NSString stringWithUTF8String: beg->m_Uri]];
                    }
                }
                else{
                    
                    _type = Normal;
                    
                    _placeHolder = [UIImage imageNamed:@"file"];
                    
                    if (data->m_Resources.GetItemCount() > 0) {
                        auto beg = data->m_Resources.GetFirstItem();
                        if ( beg->m_Size != -1)
                            _detail = uintSizeDescription( beg->m_Size );
                    }
                }
            }
        }
    }

    
}

@end

NSString* uintSizeDescription(NPT_LargeSize size)
{
    return uintSizeDescription((long long)size);
}


NSString* uintSizeDescription(long long size)
{
    const double bytes_per_kb = 1024.0;
    const double bytes_per_mb = 1024.0 * bytes_per_kb;
    const double bytes_per_gb = 1024.0 * bytes_per_mb;
    
    
    NSString *unit;
    float value;
    if (size < bytes_per_kb) {
        value = size;
        unit = @"B";
    } else if (size < bytes_per_mb) {
        value = size / bytes_per_kb;
        unit = @"KB";
    } else if(size < bytes_per_gb){
        value = size / bytes_per_mb;
        unit = @"MB";
    }
    else
    {
        value = size / bytes_per_gb;
        unit = @"G";
    }
    
    
    return [NSString stringWithFormat:@"%.1f%@",value,unit];
}


NSString *mimeTypeFromDLNAItem(CellDataA *cell)
{
    if (cell.type == Video) {
        return @"video/*";
    }
    else if( cell.type == Photo)
    {
        return @"image/*";
    }
    else if ( cell.type == Music)
    {
        return @"audio/*";
    }
    
    return nil; 
}



PLT_MediaItemResource* findResourceInMyNetwork(PLT_MediaObject *data)
{
    if (data == nullptr) {
        return nullptr;
    }
    
    NSString *ipLocal = ipLocalHost();
    
    const char *szLocal = ipLocal.UTF8String;
    auto len = ipLocal.length;
    
    const char *p = nil;
    for (int i = (int)len -1; i >= 0; i--) {
        p = szLocal+i;
        if (p[0] == '.') {
            break;
        }
    }
    
    
    char ipPub[256];
    strncpy(ipPub, szLocal, p-szLocal+1);
    ipPub[p-szLocal+1] = 0;
    
    
    NSString *ipPub2 = [NSString stringWithUTF8String:ipPub];
    
    int count =data->m_Resources.GetItemCount();
    for( auto i = 0; i < count ; i++)
    {
        auto it = data->m_Resources.GetItem(i);
        PLT_MediaItemResource item = *it;
        
        NSString *uri;
        uri = [NSString stringWithUTF8String: item.m_Uri.GetChars()];
        if ( [uri rangeOfString: ipPub2 ].length > 0 ) {
            return it;
        }
        
    }
 
    
    return nullptr;
}



///目标dlna源可能处于多个局域网，而拥有多个发布地址
///截取目标dlna item里的可用url(即与本机设备在同一局域网里的url)
NSString *uriFromDLNAItem(PLT_MediaObject *data)
{
    auto pRes =  findResourceInMyNetwork(data);
    
    if (pRes) {
        return [NSString stringWithUTF8String: pRes->m_Uri.GetChars()];
    }
    else {
        return nil;
    }
    
}



NSString *mimeTypeFromDLNAItem(PLT_MediaObjectReference data)
{
    CellDataA *cell = [[ CellDataA alloc] initWithMediaObjectRf:data];
    
    return mimeTypeFromDLNAItem(cell);
}


PLT_MediaObjectReference duplicateMediaObject(PLT_MediaObject *file)
{
    if (file->IsContainer())
    {
        PLT_MediaContainer *fileCopy = new PLT_MediaContainer(*(PLT_MediaContainer*)file);
        PLT_MediaObjectReference rf (fileCopy);
        return rf;
    }
    else
    {
        PLT_MediaItem *fileCopy = new PLT_MediaItem( (*(PLT_MediaItem*)file) );
        PLT_MediaObjectReference rf (fileCopy);
        return rf;
    }
    
}

@interface MediaDevice ()
@property (nonatomic) PLT_DeviceDataReference inner;
//-(instancetype)initWithPLT_DeviceDataReference:(PLT_DeviceDataReference)device;
@end

@implementation MediaDevice

// whether device uuid is equal
-(BOOL)isEqual:(MediaDevice*)object
{
    if (object) {
        return self.inner->GetUUID() == object.inner->GetUUID();
    }
    else{
        return FALSE;
    }
    
}

-(NSString*)GetUUID
{
    return [NSString stringWithUTF8String: _inner->GetUUID()];
}

-(NSString*)GetModelDescription
{
    return [NSString stringWithUTF8String: _inner->GetModelDescription()];
}

-(NSURL*)GetIconUrl
{
    return [NSURL URLWithString:[NSString stringWithUTF8String: _inner->GetIconUrl()]];
}

-(NSString*)GetFriendlyName
{
    return [NSString stringWithUTF8String: _inner->GetFriendlyName()];
}

-(instancetype)initWithPLT_DeviceDataReference:(PLT_DeviceDataReference)device
{
    self = [super init];
    if (self) {
        self.inner = device;
    }
    return self;
}

@end



