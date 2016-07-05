//
//  BUKMessageBar.h
//  Pods
//
//  Created by Monzy Zhang on 7/1/16.
//
//

#import <UIKit/UIKit.h>
#import "BUKMessageBarButton.h"

typedef NS_ENUM(NSInteger, BUKMessageBarType) {
    BUKMessageBarTypeSuccess,
    BUKMessageBarTypeFailed,
    BUKMessageBarTypeInfo,
    BUKMessageBarTypeLight
};

typedef NS_ENUM(NSInteger, BUKMessageBarAnimationDirection) {
    BUKMessageBarAnimationDirectionDirectionY,
    BUKMessageBarAnimationDirectionDirectionXPlus,
    BUKMessageBarAnimationDirectionDirectionXNegative,
    BUKMessageBarAnimationDirectionDirectionZ
};

@interface BUKMessageBar : UIView

@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *subtitleLabel;
@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic, assign) BOOL isShow;
@property (nonatomic, assign) BOOL belowNavigationBar;
@property (nonatomic, assign) BUKMessageBarType type;
@property (nonatomic, assign) BUKMessageBarAnimationDirection animationDirection;
@property (nonatomic, strong) NSArray<BUKMessageBarButton *> *buttons;
@property (nonatomic, strong) void (^tapHandler)(BUKMessageBar *bar);
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, assign) NSTimeInterval duration;

- (instancetype)initWithTitle:(NSString *)title 
                       detail:(NSString *)detail;

- (void)showAnimated:(BOOL)animated completion:(void (^)())completion;
- (void)dismissAnimated:(BOOL)animated completion:(void (^)())completion;
- (void)expandAnimated:(BOOL)animated expand:(BOOL)expand;
- (void)toggleAnimated:(BOOL)animated;

@end
