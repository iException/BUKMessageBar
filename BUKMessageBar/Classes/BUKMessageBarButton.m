//
//  BUKMessageBarButton.m
//  Pods
//
//  Created by Monzy Zhang on 7/3/16.
//
//

#import "BUKMessageBarButton.h"
#import "UIControl+BlocksKit.h"
#import "UIColor+bukmbmhex.h"

@implementation BUKMessageBarButton

- (instancetype)initWithWithTitle:(NSString *)title 
                             type:(BUKMessageBarButtonType)type 
                          handler:(void (^)(BUKMessageBarButton *button))block
{
    self = [super init];
    if (self) {
        [self setTitle:title forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont fontWithName:@"Avenir-Light" size:12];
        __weak typeof(self) weakSelf = self;
        [self bk_addEventHandler:^(id sender) {
            if (block) {
                block(weakSelf);
            }
        } forControlEvents:UIControlEventTouchUpInside];
        switch (type) {
            case BUKMessageBarButtonTypeDefault: {
                [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                self.backgroundColor = [UIColor buk_messageBarButton_defaultColor];
                break;
            }
            case BUKMessageBarButtonTypeOk: {
                [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                self.backgroundColor = [UIColor buk_messageBarButton_okColor];
                break;
            }
            case BUKMessageBarButtonTypeDestructive: {
                [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                self.backgroundColor = [UIColor buk_messageBarButton_destructiveColor];
                break;
            }
        }
    }
    return self;
}

+ (BUKMessageBarButton *)buttonWithTitle:(NSString *)title 
                                    type:(BUKMessageBarButtonType)type 
                                 handler:(void (^)(BUKMessageBarButton *button))block
{
    return [[BUKMessageBarButton alloc] initWithWithTitle:title type:type handler:block];
}


#pragma mark - setter -
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.layer.cornerRadius = CGRectGetHeight(frame) / 4;
}
@end
