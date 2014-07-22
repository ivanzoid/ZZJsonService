//
//  SignupRequest.m
//  StartFX
//
//  Created by Ivan on 31.01.14.
//
//

#import "ZZHttpRequest.h"
#import "NSObject+Properties.h"
#import "NSString+CapitalizedFirstLetter.h"

static NSString * const kResponsePropertiesPrefix = @"response";

@implementation ZZHttpRequest

@synthesize params = _params;
@synthesize requestType = _requestType;
@synthesize dataType = _dataType;
@synthesize scheme = _scheme;
@synthesize host = _host;
@synthesize urlPath = _urlPath;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize completionBlock = _completionBlock;
@synthesize completionQueue = _completionQueue;

AUTO_DESCRIPTION

- (ZZHttpRequestType) requestType
{
    NSAssert(NO, @"Override me");
    return ZZHttpRequestTypeGET;
}

- (ZZHttpRequestDataType) dataType
{
    NSAssert(NO, @"Override me");
    return ZZHttpRequestDataTypeJSON;
}

- (NSString *) urlPath
{
    NSAssert(NO, @"Override me");
    return @"";
}

- (ZZHttpRequestScheme) scheme
{
    return ZZHttpRequestSchemeHTTP;
}

- (NSDictionary *) params
{
    return [self paramsFromProperties];
}

- (NSTimeInterval) timeoutInterval
{
    return 0;
}

- (BOOL) processSuccessfulResponseObject:(id)responseObject
{
    NSDictionary *responseDict = responseObject;
    if (![responseDict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    NSDictionary *mapping = [self mappingForResponseValuesToProperties];
    NSArray *propertyNamesToSkip = [self mappedPropertiesNamesForResponseToSkip];

    for (NSString *key in [responseDict allKeys]) {
        if (![key isKindOfClass:[NSString class]]) {
            continue;
        }

        id value = responseDict[key];

        NSString *propertyName = key;

        NSString *mappedName = mapping[propertyName];
        if (mappedName) {
            propertyName = mappedName;
        } else {
            propertyName = [kResponsePropertiesPrefix stringByAppendingString:[propertyName capitalizedFirstLetterString]];
        }

        if ([propertyNamesToSkip containsObject:propertyName]) {
            continue;
        }

        BOOL valueIsNumber = [value isKindOfClass:[NSNumber class]];
        if (!valueIsNumber) {
            Class propertyClass = [self classOfPropertyNamed:propertyName];
            if (propertyClass && ![value isKindOfClass:propertyClass]) {
                LogCommonWarn(@"Property '%@' is present in %@, but has type of '%@' instead of '%@' - skipping", propertyName, NSStringFromClass([self class]), NSStringFromClass(propertyClass), NSStringFromClass([value class]));
                continue;
            }
        }

        NSString *setterName = [NSString stringWithFormat:@"set%@:", [propertyName capitalizedFirstLetterString]];
        SEL setterSelector = NSSelectorFromString(setterName);
        if ([self respondsToSelector:setterSelector]) {
            [self setValue:value forKey:propertyName];
        }
    }

    return YES;
}

- (NSDictionary *) mappingForResponseValuesToProperties
{
    return nil;
}

- (void) processUnsuccessfulResponse:(NSHTTPURLResponse *)response error:(NSError *)error responseObject:(id)responseObject
{
    self.responseError = error;
}

- (NSMutableDictionary *) paramsFromProperties
{
    return [self paramsFromPropertiesExcept:nil];
}

- (NSMutableDictionary *) paramsFromPropertiesExcept:(NSArray *)propertiesNamesToSkip
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSDictionary *mapping = [self mappingForPropertiesToRequestParams];

    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (unsigned int i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        NSString *name = @(property_getName(property));

        if ([name hasPrefix:kResponsePropertiesPrefix]) {
            continue;
        }
        if ([propertiesNamesToSkip containsObject:name]) {
            continue;
        }

        id value = nil;
        SEL getterSelector = NSSelectorFromString(name);
        if ([self respondsToSelector:getterSelector]) {
            value = [self valueForKey:name];
        }
        if (value) {
            NSString *paramName = [mapping objectForKey:name];
            if (paramName) {
                name = paramName;
            }

            params[name] = value;
        }
    }

    free(properties);

    return params;
}

- (NSDictionary *) mappingForPropertiesToRequestParams
{
    return nil;
}

- (NSArray *) mappedPropertiesNamesForResponseToSkip
{
    return nil;
}

@end
