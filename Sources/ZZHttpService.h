//
//  ZZHttpService.h
//

@protocol ZZHttpRequest;
@protocol ZZHttpServiceDelegate;
@class AFHTTPRequestOperationManager;

@interface ZZHttpService : NSObject

@property (nonatomic, weak) id <ZZHttpServiceDelegate> delegate;

/// @note If baseUrl AND host are nil, each request must return full URL in urlPath.
/// @note baseUrl takes precedense over host when both are non-empty.
/// @note If baseUrl is nil and host is non-nil, scheme will be taken from request to construct path.
@property (nonatomic) NSString *baseUrl;
@property (nonatomic) NSString *host;
/// urlPrefix is prepended to 'urlPath' of request.
@property (nonatomic) NSString *urlPrefix;

- (void) setBasicAuthorizationLogin:(NSString *)login password:(NSString *)password;

/// If nonzero and request's timeoutInterval is zero, sets requests' timeoutInterval to this value.
/// Default is 60.
@property (nonatomic) NSTimeInterval defaultTimeoutInterval;
/// Appended to params for each requests.
@property (nonatomic) NSDictionary *allRequestsParams;

/// Asynchronously performs a request.
/// @note If completion block is present, it will overwrite request's completionBlock.
- (BOOL) performRequest:(id<ZZHttpRequest>)request completion:(dispatch_block_t)completion;
- (BOOL) performRequest:(id<ZZHttpRequest>)request;

@property (nonatomic, readonly) AFHTTPRequestOperationManager *requestOperationManager;

// For overriding in subclasses:

- (NSDictionary *) additionalParamsForRequest:(id<ZZHttpRequest>)request;
- (NSDictionary *) additionalHeadersForRequest:(id<ZZHttpRequest>)request;

- (void) didProcessRequest:(id<ZZHttpRequest>)request withUrl:(NSString *)urlString;
- (void) willSendRequest:(id<ZZHttpRequest>)request withUrl:(NSString *)urlString;

@end


@protocol ZZHttpServiceDelegate <NSObject>

- (void) httpService:(ZZHttpService *)service willSendRequest:(id<ZZHttpRequest>)request withUrl:(NSString *)urlString;
- (void) httpService:(ZZHttpService *)service didProcessRequest:(id<ZZHttpRequest>)request withUrl:(NSString *)urlString;

@end