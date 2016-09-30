//
//  SMSColors.m
//  SMS Scheduler
//Created by ilabafrica on 24/08/2016.
// Copyright © 2016 Strathmore. All rights reserved.


#import "SMSColors.h"

@implementation SMSColors

+ (UIColor *)defaultColor {
    return colorWithHexString(@"#34aadc");
}

+ (UIColor *)text{
    return colorWithHexString(@"#6a6a6a");
}

+ (UIColor *)backgroundColor {
    return colorWithHexString(@"#e7e7e7");
}

+ (UIColor *)emptyState {
    return colorWithHexString(@"#b8b8b8");
}

+ (UIColor *)alertColor {
    return colorWithHexString(@"e67e22");
}

static UIColor *colorWithHexString(NSString *hexString) {
    
    NSMutableString *s = [hexString mutableCopy];
    [s replaceOccurrencesOfString:@"#" withString:@"" options:0 range:NSMakeRange(0, [hexString length])];
    CFStringTrimWhitespace((__bridge CFMutableStringRef)s);
    
    NSString *redString = [s substringToIndex:2];
    NSString *greenString = [s substringWithRange:NSMakeRange(2, 2)];
    NSString *blueString = [s substringWithRange:NSMakeRange(4, 2)];
    
    unsigned int red = 0, green = 0, blue = 0;
    [[NSScanner scannerWithString:redString] scanHexInt:&red];
    [[NSScanner scannerWithString:greenString] scanHexInt:&green];
    [[NSScanner scannerWithString:blueString] scanHexInt:&blue];
    
    return [UIColor colorWithRed:(CGFloat)red/255.0f green:(CGFloat)green/255.0f blue:(CGFloat)blue/255.0f alpha:1.0f];
}

@end
