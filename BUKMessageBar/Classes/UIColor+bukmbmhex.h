//
//  UIColor+bukmbmhex.h
//  Pods
//
//  Created by Monzy Zhang on 7/3/16.
//
//

#import <UIKit/UIKit.h>

@interface UIColor (hex)

+ (UIColor *)colorWithHex:(NSString *)hex;

+ (UIColor *)buk_tb_successColor;
+ (UIColor *)buk_tb_infoColor;
+ (UIColor *)buk_tb_failedColor;
+ (UIColor *)buk_tb_lightColor;
+ (UIColor *)buk_messageBar_background;
+ (UIColor *)buk_messageBarButton_defaultColor;
+ (UIColor *)buk_messageBarButton_okColor;
+ (UIColor *)buk_messageBarButton_destructiveColor;
@end
