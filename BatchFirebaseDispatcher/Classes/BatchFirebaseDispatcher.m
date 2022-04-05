#import <Foundation/Foundation.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>

#import "BatchFirebaseDispatcher.h"

#define DISPATCHER_NAME @"firebase"
#define DISPATCHER_VERSION 1

NSString* const BatchFirebaseUtmCampaign = @"utm_campaign";
NSString* const BatchFirebaseUtmSource = @"utm_source";
NSString* const BatchFirebaseUtmMedium = @"utm_medium";
NSString* const BatchFirebaseUtmContent = @"utm_content";

NSString* const BatchFirebaseCampaign = @"campaign";
NSString* const BatchFirebaseSource = @"source";
NSString* const BatchFirebaseMedium = @"medium";
NSString* const BatchFirebaseContent = @"content";

NSString* const BatchFirebaseTrackingId = @"batch_tracking_id";
NSString* const BatchFirebaseWebViewAnalyticsId = @"batch_webview_analytics_id";

@implementation BatchFirebaseDispatcher

+ (void)load {
    [BatchEventDispatcher addDispatcher:[self instance]];
}

+ (instancetype)instance
{
    static BatchFirebaseDispatcher *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BatchFirebaseDispatcher alloc] init];
    });
    
    return sharedInstance;
}

- (void)dispatchEventWithType:(BatchEventDispatcherType)type payload:(nonnull id<BatchEventDispatcherPayload>)payload
{
    NSDictionary<NSString *, id> *parameters = nil;
    if ([BatchEventDispatcher isNotificationEvent:type]) {
        parameters = [self notificationParamsFromPayload:payload];
    } else if ([BatchEventDispatcher isMessagingEvent:type]) {
        parameters = [self inAppParamsFromPayload:payload];
    }

    [FIRAnalytics logEventWithName:[self stringFromEventType:type] parameters:parameters];
}

-(nullable NSDictionary<NSString *, id> *)inAppParamsFromPayload:(nonnull id<BatchEventDispatcherPayload>)payload
{
    NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary dictionary];
    
    // Init with default values
    [parameters setValue:payload.trackingId forKey:BatchFirebaseCampaign];
    [parameters setValue:@"batch" forKey:BatchFirebaseSource];
    [parameters setValue:@"in-app" forKey:BatchFirebaseMedium];
    [parameters setValue:payload.trackingId forKey:BatchFirebaseTrackingId];
    
    if (payload.webViewAnalyticsIdentifier != nil) {
        [parameters setValue:payload.webViewAnalyticsIdentifier forKey:BatchFirebaseWebViewAnalyticsId];
    }
    
    NSString *deeplink = payload.deeplink;
    if (deeplink != nil) {
        deeplink = [deeplink stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSURL *url = [NSURL URLWithString:deeplink];
        if (url != nil) {
            NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:false];
            if (components != nil) {
                
                // Override with values from URL fragment parameters
                if (components.fragment != nil) {
                    NSDictionary *fragments = [self dictFragment:components.fragment];
                    [self addParam:parameters fromFragment:fragments fromKey:BatchFirebaseUtmContent outKey:BatchFirebaseContent];
                }
                
                // Override with values from URL query parameters
                [self addParam:parameters fromUrl:components fromKey:BatchFirebaseUtmContent outKey:BatchFirebaseContent];
            }
        }
    }
    
    // Override with values from custom payload
    [self addParam:parameters fromPayload:payload fromKey:BatchFirebaseUtmCampaign outKey:BatchFirebaseCampaign];
    [self addParam:parameters fromPayload:payload fromKey:BatchFirebaseUtmSource outKey:BatchFirebaseSource];
    [self addParam:parameters fromPayload:payload fromKey:BatchFirebaseUtmMedium outKey:BatchFirebaseMedium];
    return parameters;
}

-(nullable NSDictionary<NSString *, id> *)notificationParamsFromPayload:(nonnull id<BatchEventDispatcherPayload>)payload
{
    NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary dictionary];
    
    // Init with default values
    [parameters setValue:@"batch" forKey:BatchFirebaseSource];
    [parameters setValue:@"push" forKey:BatchFirebaseMedium];
    
    NSString *deeplink = payload.deeplink;
    if (deeplink != nil) {
        deeplink = [deeplink stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSURL *url = [NSURL URLWithString:deeplink];
        if (url != nil) {
            NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:false];
            if (components != nil) {
            
                // Override with values from URL fragment parameters
                if (components.fragment != nil) {
                    NSDictionary *fragments = [self dictFragment:components.fragment];
                    [self addParam:parameters fromFragment:fragments fromKey:BatchFirebaseUtmCampaign outKey:BatchFirebaseCampaign];
                    [self addParam:parameters fromFragment:fragments fromKey:BatchFirebaseUtmSource outKey:BatchFirebaseSource];
                    [self addParam:parameters fromFragment:fragments fromKey:BatchFirebaseUtmMedium outKey:BatchFirebaseMedium];
                    [self addParam:parameters fromFragment:fragments fromKey:BatchFirebaseUtmContent outKey:BatchFirebaseContent];
                }
            
                // Override with values from URL query parameters
                [self addParam:parameters fromUrl:components fromKey:BatchFirebaseUtmCampaign outKey:BatchFirebaseCampaign];
                [self addParam:parameters fromUrl:components fromKey:BatchFirebaseUtmSource outKey:BatchFirebaseSource];
                [self addParam:parameters fromUrl:components fromKey:BatchFirebaseUtmMedium outKey:BatchFirebaseMedium];
                [self addParam:parameters fromUrl:components fromKey:BatchFirebaseUtmContent outKey:BatchFirebaseContent];
            }
        }
    }
    
    // Override with values from custom payload
    [self addParam:parameters fromPayload:payload fromKey:BatchFirebaseUtmCampaign outKey:BatchFirebaseCampaign];
    [self addParam:parameters fromPayload:payload fromKey:BatchFirebaseUtmSource outKey:BatchFirebaseSource];
    [self addParam:parameters fromPayload:payload fromKey:BatchFirebaseUtmMedium outKey:BatchFirebaseMedium];
    return parameters;
}

-(NSDictionary*)dictFragment:(nonnull NSString*)fragment
{
    NSMutableDictionary<NSString *, id> *fragments = [NSMutableDictionary dictionary];
    NSArray *fragmentComponents = [fragment componentsSeparatedByString:@"&"];
    for (NSString *keyValuePair in fragmentComponents) {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[[pairComponents firstObject] stringByRemovingPercentEncoding] lowercaseString];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];

        [fragments setObject:value forKey:key];
    }
    return fragments;
}

-(void)addParam:(nonnull NSMutableDictionary<NSString *, id> *)parameters
   fromFragment:(nonnull NSDictionary*)fragments
        fromKey:(nonnull NSString*)fromKey
         outKey:(nonnull NSString*)outKey
{
    NSObject *value = [fragments objectForKey:fromKey];
    if (value != nil) {
        [parameters setValue:value forKey:outKey];
    }
}

-(void)addParam:(nonnull NSMutableDictionary<NSString *, id> *)parameters
        fromUrl:(nonnull NSURLComponents*)components
        fromKey:(nonnull NSString*)fromKey
         outKey:(nonnull NSString*)outKey
{
    for (NSURLQueryItem *item in components.queryItems) {
        if ([fromKey caseInsensitiveCompare:item.name] == NSOrderedSame) {
            [parameters setValue:item.value forKey:outKey];
            return;
        }
    }
}

-(void)addParam:(nonnull NSMutableDictionary<NSString *, id> *)parameters
    fromPayload:(nonnull id<BatchEventDispatcherPayload>)payload
        fromKey:(nonnull NSString*)fromKey
         outKey:(nonnull NSString*)outKey
{
    NSObject *value = [payload customValueForKey:fromKey];
    if (value != nil) {
        [parameters setValue:value forKey:outKey];
    }
}

- (nonnull NSString*)stringFromEventType:(BatchEventDispatcherType)eventType
{
    switch (eventType) {
        case BatchEventDispatcherTypeNotificationOpen:
            return @"batch_notification_open";
        case BatchEventDispatcherTypeMessagingShow:
            return @"batch_in_app_show";
        case BatchEventDispatcherTypeMessagingCloseError:
            return @"batch_in_app_close_error";
        case BatchEventDispatcherTypeMessagingClose:
            return @"batch_in_app_close";
        case BatchEventDispatcherTypeMessagingAutoClose:
            return @"batch_in_app_auto_close";
        case BatchEventDispatcherTypeMessagingClick:
            return @"batch_in_app_click";
        case BatchEventDispatcherTypeMessagingWebViewClick:
            return @"batch_in_app_webview_click";
        default:
            return @"batch_unknown";
    }
}

- (nonnull NSString*)name
{
    return DISPATCHER_NAME;
}

- (NSUInteger)version
{
    return DISPATCHER_VERSION;
}

@end

