//
//  ZZHttpService.m
//

#import "ZZHttpService.h"
#import "ZZHttpRequest.h"
#import "AFNetworking.h"

@implementation ZZHttpService

static NSTimeInterval kDefaultDefaultTimeoutInterval = 60;

- (id) init
{
    if ((self = [super init])) {
        _requestOperationManager = [AFHTTPRequestOperationManager new];
        self.defaultTimeoutInterval = kDefaultDefaultTimeoutInterval;
    }
    return self;
}

- (void) setBasicAuthorizationLogin:(NSString *)login password:(NSString *)password
{
    _requestOperationManager.credential = [NSURLCredential credentialWithUser:login password:password persistence:NSURLCredentialPersistenceNone];
}

- (BOOL) processDataResponse:(id)responseObject
                  forRequest:(id<ZZHttpRequest>)request
                       error:(NSError **)errorPtr
                resultString:(NSString **)resultStringPtr
{
    NSString *parseErrorString = [NSString stringWithFormat:@"%@: can't parse response", NSStringFromClass([request class])];

    NSData *responseData = responseObject;
    if (![responseData isKindOfClass:[NSData class]]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithLocalizedDescription:parseErrorString];
        }
        return NO;
    }
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    if (!responseString) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithLocalizedDescription:parseErrorString];
        }
        return NO;
    }

    if (resultStringPtr) {
        *resultStringPtr = responseString;
    }
    return YES;
}

- (void) handleSuccessForRequest:(id<ZZHttpRequest>)request
                       operation:(AFHTTPRequestOperation *)operation
                    responseObject:(id)responseObject
{
    LogApiVerbose(@"responseData: %@", [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);

    if ([request dataType] == ZZHttpRequestDataTypeString) {
        NSString *responseString = nil;
        NSError *error = nil;
        if ([self processDataResponse:responseObject forRequest:request error:&error resultString:&responseString]) {
            [request processSuccessfulResponseObject:responseString];
        } else {
            [request processUnsuccessfulResponse:operation.response error:error responseObject:responseObject];
        }
    } else {
        [request processSuccessfulResponseObject:responseObject];
    }
}

- (void) handleFailureForRequest:(id<ZZHttpRequest>)request
                       operation:(AFHTTPRequestOperation *)operation
                           error:(NSError *)error
{
    LogApiError(@"responseData: %@", [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);

    id responseObject = operation.responseObject;

    [request processUnsuccessfulResponse:operation.response error:error responseObject:responseObject];
}

- (AFHTTPRequestOperation *) operationForRequest:(id<ZZHttpRequest>)request
                                         success:(void (^)(AFHTTPRequestOperation *, id))success
                                         failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    NSString *method = nil;
    if (request.requestType == ZZHttpRequestTypeGET) {
        method = @"GET";
    } else if (request.requestType == ZZHttpRequestTypePOST) {
        method = @"POST";
    } else {
        NSAssert(NO, nil);
    }

    NSAssert(request.urlPath, nil);

    NSMutableDictionary *params = [NSMutableDictionary new];
    [params addEntriesFromDictionary:request.params];
    [params addEntriesFromDictionary:self.allRequestsParams];
    [params addEntriesFromDictionary:[self additionalParamsForRequest:request]];

    if ([params count] == 0) {
        params = nil;
    }

    NSString *fullUrlString = [[self fullUrlForRequest:request] absoluteString];

    NSMutableURLRequest *urlRequest = [_requestOperationManager.requestSerializer requestWithMethod:method URLString:fullUrlString parameters:params error:nil];

    urlRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    NSDictionary *headers = [self additionalHeadersForRequest:request];
    for (NSString *headerKey in headers) {
        NSString *headerValue = headers[headerKey];
        [urlRequest setValue:headerValue forHTTPHeaderField:headerKey];
    }

    AFHTTPRequestOperation *operation = [_requestOperationManager HTTPRequestOperationWithRequest:urlRequest success:success failure:failure];
    [_requestOperationManager.operationQueue addOperation:operation];
    
    return operation;
}

- (NSURL *) fullUrlForRequest:(id<ZZHttpRequest>)request
{
    NSParameterAssert(request.urlPath);

    NSURL *baseURL = nil;
    if (self.requestOperationManager.baseURL) {
        baseURL = self.requestOperationManager.baseURL;
    } else {
        NSString *host = nil;
        if (request.host) {
            host = request.host;
        } else {
            host = self.host;
        }

        if (host) {
            if (request.scheme == ZZHttpRequestSchemeHTTP) {
                baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", host]];
            } else if (request.scheme == ZZHttpRequestSchemeHTTPS) {
                baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", host]];
            }
        }
    }
    
    NSString *urlPath = request.urlPath;
    if (self.urlPrefix) {
        urlPath = [self.urlPrefix stringByAppendingPathComponent:request.urlPath];
    }

    NSURL *fullURL = [NSURL URLWithString:urlPath relativeToURL:baseURL];
    return fullURL;
}

- (void) didProcessRequest:(id<ZZHttpRequest>)request withUrl:(NSString *)urlString
{
    
}

- (void) willSendRequest:(id<ZZHttpRequest>)request withUrl:(NSString *)urlString
{
    
}

#pragma mark - Public

- (BOOL) performRequest:(id<ZZHttpRequest>)request
{
    BOOL result = [self performRequest:request completion:nil];
    return result;
}

- (BOOL) performRequest:(id<ZZHttpRequest>)request completion:(dispatch_block_t)completion
{
    NSParameterAssert(request);

    WEAKSELF weakSelf = self;
    BLOCK AFHTTPRequestOperation *operation = nil;

    void (^callCompletionBlock)() = ^{
        if (request.completionBlock) {
            dispatch_queue_t dispatchQueue = request.completionQueue;
            if (dispatchQueue == nil) {
                dispatchQueue = dispatch_get_main_queue();
            }
            dispatch_async(dispatchQueue, request.completionBlock);
        }
    };

    void (^notifyDelegateThatWeDidProcessRequest)() = ^{
        STRONGSELF strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(httpService:didProcessRequest:withUrl:)]) {
            [strongSelf.delegate httpService:strongSelf didProcessRequest:request withUrl:[[operation.request URL] absoluteString]];
        }
    };

    if (completion) {
        request.completionBlock = completion;
    }

    operation = [self operationForRequest:request
        success:^(AFHTTPRequestOperation *operation_, id responseObject)
        {
            STRONGSELF strongSelf = weakSelf;
            [strongSelf handleSuccessForRequest:request operation:operation_ responseObject:responseObject];
            [strongSelf didProcessRequest:request withUrl:[[operation.request URL] absoluteString]];
            notifyDelegateThatWeDidProcessRequest();
            callCompletionBlock();
        }
        failure:^(AFHTTPRequestOperation *operation_, NSError *error) {
            STRONGSELF strongSelf = weakSelf;
            [strongSelf handleFailureForRequest:request operation:operation_ error:error];
            notifyDelegateThatWeDidProcessRequest();
            callCompletionBlock();
        }
    ];

    if ([self.delegate respondsToSelector:@selector(httpService:willSendRequest:withUrl:)]) {
        [self willSendRequest:request withUrl:[[operation.request URL] absoluteString]];
        [self.delegate httpService:self willSendRequest:request withUrl:[[operation.request URL] absoluteString]];
    }

    return YES;
}

- (NSDictionary *) additionalParamsForRequest:(id<ZZHttpRequest>)request
{
    return @{};
}

- (NSDictionary *) additionalHeadersForRequest:(id<ZZHttpRequest>)request
{
    return @{};
}

@end
