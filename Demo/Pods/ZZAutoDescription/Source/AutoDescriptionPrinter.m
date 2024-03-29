//
//  AutoDescriptionPrinter.m
//  iHerb
//
//  Created by Ivan Zezyulya on 15.04.14.
//  Copyright (c) 2014 aldigit. All rights reserved.
//

#import "AutoDescriptionPrinter.h"

@implementation AutoDescriptionPrinter {
    NSMutableSet *printedObjects;
    NSMutableString *buffer;
}

- (id) init
{
    if ((self = [super init])) {
        self.indentSpaces = 2;
        
        buffer = [NSMutableString new];
        printedObjects = [NSMutableSet new];
    }
    return self;
}

- (void) printLine:(NSString *)line
{
    [self printIndent];
    [self printText:line];
    [self printNewLine];
}

- (void) printIndent
{
    NSInteger spacesToIndent = self.indentSpaces * _currentIndentLevel;
    NSString *indentText = [@" " stringByPaddingToLength:spacesToIndent withString:@" " startingAtIndex:0];
    [buffer appendString:indentText];
}

- (void) printText:(NSString *)text
{
    [buffer appendString:text];
}

- (void) printNewLine
{
    [buffer appendString:@"\n"];
}

- (void) increaseIndent
{
    _currentIndentLevel++;
}

- (void) decreaseIndent
{
    _currentIndentLevel--;
}

- (void) registerPrintedObject:(id)printedObject
{
    [printedObjects addObject:printedObject];
}

- (BOOL) isObjectAlreadyPrinted:(id)object
{
    BOOL result = [printedObjects containsObject:object];
    return result;
}

- (NSString *) buffer
{
    return buffer;
}

- (NSString *) result
{
    return buffer;
}

@end
