//
//  UIColor+bukmbmhex.m
//  Pods
//
//  Created by Monzy Zhang on 7/3/16.
//
//

#import "UIColor+bukmbmhex.h"

@implementation UIColor (bukmbmhex)

+ (UIColor *)colorWithHex:(NSString *)hex
{
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    UIColor *color = nil;
    
    unsigned integer;
    [scanner scanHexInt:&integer];
    if (hex.length == 6) {
        color = [UIColor colorWithRed:(integer >> 16) / 255.0f green:(integer >> 8) % 256 / 255.0f blue:integer % 256 / 255.0f alpha:1.0];
    } else if (hex.length == 3) {
        color = [UIColor colorWithRed:(integer >> 8) * 17 / 255.0f green:(integer >> 4) % 16 * 17 / 255.0f blue:integer % 16 * 17 / 255.0f alpha:1.0];
    }
    return color;    
}

+ (UIColor *)buk_tb_successColor
{
    return [UIColor colorWithHex:@"84E027"];
}

+ (UIColor *)buk_tb_infoColor
{
    return [UIColor colorWithHex:@"FF4466"];
}

+ (UIColor *)buk_tb_failedColor
{
    return [UIColor colorWithHex:@"FF0000"];
}

+ (UIColor *)buk_tb_lightColor
{
    return [UIColor colorWithHex:@"EDECEC"];
}

+ (UIColor *)buk_messageBar_background
{
    return [UIColor colorWithHex:@"EDECEC"];
}

+ (UIColor *)buk_messageBarButton_defaultColor
{
    return [UIColor colorWithHex:@"D8D8D8"];
}

+ (UIColor *)buk_messageBarButton_okColor
{
    return [UIColor buk_tb_infoColor];
}

+ (UIColor *)buk_messageBarButton_destructiveColor
{
    return [UIColor colorWithHex:@"FF0000"];
}

@end
