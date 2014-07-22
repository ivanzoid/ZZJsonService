//
//  SignupRequest.h
//

typedef NS_ENUM(NSInteger, ZZHttpRequestType) {
    ZZHttpRequestTypeGET,
    ZZHttpRequestTypePOST
};

typedef NS_ENUM(NSInteger, ZZHttpRequestDataType) {
    ZZHttpRequestDataTypeData,
    ZZHttpRequestDataTypeString,
    ZZHttpRequestDataTypeJSON
};

typedef NS_ENUM(NSInteger, ZZHttpRequestScheme) {
    ZZHttpRequestSchemeHTTP,
    ZZHttpRequestSchemeHTTPS
};

@protocol ZZHttpRequest <NSObject>

@required
@property (nonatomic, readonly) ZZHttpRequestType requestType;
@property (nonatomic, readonly) ZZHttpRequestDataType dataType;
@property (nonatomic, readonly) NSString *urlPath;

@optional
@property (nonatomic, readonly) ZZHttpRequestScheme scheme;
@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSDictionary *params;
@property (nonatomic, readonly) NSTimeInterval timeoutInterval; // Set to 0 for default timeout interval
@property (nonatomic, copy) dispatch_block_t completionBlock;
@property (nonatomic, copy) dispatch_queue_t completionQueue; // If nil, main queue will be used

- (void) processSuccessfulResponseObject:(id)responseObject;
- (void) processUnsuccessfulResponse:(NSHTTPURLResponse *)response error:(NSError *)error responseObject:(id)responseObject;

@end

@interface ZZHttpRequest : NSObject <ZZHttpRequest>

/// By default, 'params' property will contain result of calling paramsFromProperties.
/// Override to provide your own parameters, or override mappingForPropertiesToRequestParams
/// to control mapping of property names to names of parameters in request.
@property (nonatomic, readonly) NSDictionary *params;

/// Generates params dictionary using Objective-C runtime.
/// @note Properties starting with 'response' prefix are skipped.
/// @note Use ZZHttpRequestMapProperty macro for making easier mappings with compile-time checks.
/// @note This won't work for properties with nonstandard-named getters.
- (NSMutableDictionary *) paramsFromProperties;

/// Used only in paramsFromProperties and paramsFromPropertiesExcept: calls.
/// Should return dictionary which maps property names to request
/// Default implementation returns nil.
/// Use ZZHttpRequestMapProperty for easier mapping with compile-time checks.
- (NSDictionary *) mappingForPropertiesToRequestParams;

/// Will try to automatically process response and fill properties of class with response data.
/// Detailed: will try to treat response as dictionary, and map its keys&values to properties of class
/// with the following mapping rule: if property has name like 'responseXxx' it will be mapped to key 'xxx'.
/// @note Properties names returned in mappedPropertiesNamesForResponseToSkip are skipped.
/// @note This won't work for properties with nonstandard-named setters.
- (BOOL) processSuccessfulResponseObject:(id)responseObject;

/// Used only in processSuccessfulResponseObject: method.
/// Should return dictionary which keys in reponse dictionary to property names of class.
/// Default implementation returns nil.
- (NSDictionary *) mappingForResponseValuesToProperties;

/// Return names of properties which shouldn't be automatically filled in processSuccessfulResponseObject.
/// You will usually provide this function if you want to parse some of the response data manually (in processSuccessfulResponseObject:).
/// Default implementation returns nil.
- (NSArray *) mappedPropertiesNamesForResponseToSkip;

/// Just sets self.responseError.
- (void) processUnsuccessfulResponse:(NSHTTPURLResponse *)response error:(NSError *)error responseObject:(id)responseObject;

// Output
@property (nonatomic) NSError *responseError;

@end


#define ZZHttpRequestMapProperty(propertyName) NSStringFromSelector(@selector(propertyName))
