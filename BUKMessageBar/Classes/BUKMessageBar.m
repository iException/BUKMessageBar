//
//  BUKMessageBar.m
//  Pods
//
//  Created by Monzy Zhang on 7/1/16.
//
//

#import "BUKMessageBar.h"
#import "UIColor+bukmbmhex.h"
#import "UIControl+Blockskit.h"
#import "NSTimer+Blockskit.h"
#import "UIGestureRecognizer+Blockskit.h"

#define kStatusBarHeight 20.0
#define kButtonContainerHeight 35.0
#define kPadding 15.0
#define kButtonSpace 10.0
#define kButtonTopPadding 6.0
#define kRadius 6.0

#define kTopButtonWidth 30.0
#define kZHeight 30.0
#define kExpandButtonTitle @"展开"
#define kFoldButtonTitle @"折叠"
#define kDefaultDuration 0.25
#define kDefaultLast 3.0
#define kDismissViewAlpha 0.3

#define kDefaultAnimationDirection BUKMessageBarAnimationDirectionZ
#define kDefaultType BUKMessageBarTypeLight

@implementation UIWindow (BUKMessageBarManagerMainWindow)

+ (UIView *)mainWindow
{
    NSEnumerator *frontToBackWindows = [[[UIApplication sharedApplication] windows] reverseObjectEnumerator];
    
    for (UIWindow *window in frontToBackWindows)
        if (window.windowLevel == UIWindowLevelNormal) {
            return window;
        }
    return nil;
}

@end

@implementation UIViewController (BUKMessageBar)

+ (UIViewController *)topMostViewController
{
    UIViewController *rootViewController = ([UIApplication sharedApplication].delegate).window.rootViewController;
    
    return [self topViewControllerOfController:rootViewController];
}

+ (UIViewController *)topViewControllerOfController:(UIViewController *)controller
{
    if (controller.presentedViewController) {
        return [self topViewControllerOfController:controller.presentedViewController];
    }
    
    if ([controller isKindOfClass:[UITabBarController class]]) {
        return [self topViewControllerOfController:[(UITabBarController *)controller selectedViewController]];
    }
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        return [self topViewControllerOfController:[(UINavigationController *)controller topViewController]];
    }
    
    return controller;
}

@end

@interface BUKMessageBar ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIView *titleContainerView;
@property (nonatomic, strong) UIView *buttonsContainerView;
@property (nonatomic, strong) UIView *detailContentView;
@property (nonatomic, strong) UIButton *dismissBackgroundButton;
@property (nonatomic, strong) CAShapeLayer *titleBackgroundLayer;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, assign) CGFloat expandHeight;
@property (nonatomic, assign) CGFloat foldHeight;
@property (nonatomic, assign) CGPoint previousPanPoint;
@property (nonatomic, assign) CGFloat smartYTemp; 

@end

@implementation BUKMessageBar
@synthesize color = _color;

#pragma mark - lifecycle -
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.type = kDefaultType;
        self.animationDirection = kDefaultAnimationDirection;
        self.duration = kDefaultLast;
        self.expanded = NO;
        self.enableDismissMask = YES;
        self.enableSmartY = YES;
        self.smartYTemp = -1.0;
        __weak typeof(self) weakSelf = self;
        [self addGestureRecognizer:[UIPanGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (!weakSelf.superview) {
                return;
            }
            CGPoint locationInMainWindow = [sender locationInView:weakSelf.superview];
            CGRect frame = weakSelf.frame;
            switch (state) {
                case UIGestureRecognizerStateBegan:
                    [weakSelf stopDismissTimer];
                    break;
                case UIGestureRecognizerStateChanged: {
                    frame.origin.x += locationInMainWindow.x - weakSelf.previousPanPoint.x;
                    weakSelf.frame = frame;
                    break;
                }
                case UIGestureRecognizerStateCancelled: {
                    if (!weakSelf.expanded) {
                        [weakSelf initDismissTimer];
                    }
                    break;
                }
                case UIGestureRecognizerStateFailed:
                case UIGestureRecognizerStateEnded: {
                    if (!weakSelf.expanded) {
                        [weakSelf initDismissTimer];
                    }
                    [weakSelf endPan];
                    break;
                }
                default:
                    break;
            }
            weakSelf.previousPanPoint = locationInMainWindow;
        }]];
        [self setup];
        [self initKVO];
        [self initObservers];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title 
                       detail:(NSString *)detail
{
    if ([self initWithFrame:CGRectZero]) {
        self.titleLabel.text = title;
        self.detailLabel.text = detail;
    }
    return self;
}


- (void)dealloc
{
    [_titleLabel removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
    [_detailLabel removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
}

#pragma mark - touches -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self stopDismissTimer];
}

#pragma mark - kvo -
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == self.titleLabel && [keyPath isEqualToString:NSStringFromSelector(@selector(text))]) 
        || 
        (object == self.detailLabel && [keyPath isEqualToString:NSStringFromSelector(@selector(text))])) {
        [self setupFrame];
    }
}

#pragma mark - public -
- (void)showAnimated:(BOOL)animated completion:(void (^)())completion
{
    if (!self.expanded) { 
        [self initDismissTimer];
    }
    if (!self.superview) {
        [[UIWindow mainWindow] addSubview:self];
    }
    if (self.isShow) {
        return;
    }
    self.isShow = true;
    CGRect frame = self.bounds;
    CGRect currentFrame = self.frame;
    switch (self.animationDirection) {
        case BUKMessageBarAnimationDirectionY:{
            currentFrame.origin.y = -CGRectGetHeight(currentFrame);
            break;
        }
        case BUKMessageBarAnimationDirectionXPlus:{
            currentFrame.origin.y = self.startY;
            currentFrame.origin.x = -CGRectGetWidth(currentFrame);
            break;
        }
        case BUKMessageBarAnimationDirectionXNegative:{
            currentFrame.origin.y = self.startY;
            currentFrame.origin.x = CGRectGetWidth([UIScreen mainScreen].bounds) + CGRectGetWidth(currentFrame);
            break;
        }
        case BUKMessageBarAnimationDirectionZ:{
            currentFrame.origin.y = self.startY;
            currentFrame.origin.x = kPadding;
            CATransform3D transform = CATransform3DMakeTranslation(0, 0, kZHeight);
            transform.m34 = -1.0 / 500.0;
            self.layer.transform = transform;
            self.alpha = 0.0;
            break;
        }
    }
    self.frame = currentFrame;
    frame.origin.y = self.startY;
    frame.origin.x = kPadding;
    [self setFrame:frame 
         transform:CATransform3DIdentity 
             alpha:1.0 
          animated:animated 
        completion:completion];
    if (self.expanded) {
        [self showDismissBackgroundButtonAnimated:animated];
    }
}

- (void)showAnimated:(BOOL)animated direction:(BUKMessageBarAnimationDirection)direction completion:(void (^)())completion
{
    BUKMessageBarAnimationDirection tempDirection = self.animationDirection;
    self.animationDirection = direction;
    [self showAnimated:animated completion:^{
        if (completion) {
            completion();
        }
        self.animationDirection = tempDirection;
    }];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)())completion
{
    if (!self.isShow) {
        return;
    }
    CATransform3D transform = CATransform3DIdentity;
    CGFloat alpha = 1.0;
    if (self.animationDirection == BUKMessageBarAnimationDirectionZ) {
        transform = CATransform3DMakeTranslation(0, 0, kZHeight);
        alpha = 0.0;
    }
    self.isShow = false;
    CGRect frame = self.bounds;

    switch (self.animationDirection) {
        case BUKMessageBarAnimationDirectionY:{
            frame.origin.y = -CGRectGetHeight(frame);
            frame.origin.x += kPadding;
            break;
        }
        case BUKMessageBarAnimationDirectionXPlus:{
            frame.origin.y = self.startY;
            frame.origin.x = -CGRectGetWidth(frame);
            break;
        }
        case BUKMessageBarAnimationDirectionXNegative:{
            frame.origin.y = self.startY;
            frame.origin.x = CGRectGetWidth([UIScreen mainScreen].bounds) + CGRectGetWidth(frame);
            break;
        }
        case BUKMessageBarAnimationDirectionZ:{            
            transform = CATransform3DMakeTranslation(0, 0, kZHeight);
            transform.m34 = -1.0 / 500.0;
            alpha = 0.0;
            break;
        }
    }

    [self setFrame:frame
         transform:transform 
             alpha:alpha
          animated:animated
        completion:^{
            if (completion) {
                completion();
            }
            [self removeFromSuperview];
        }];

    [self dismissDismissBackgroundButtonAnimated:animated];
}

- (void)dismissAnimated:(BOOL)animated direction:(BUKMessageBarAnimationDirection)direction completion:(void (^)())completion
{
    BUKMessageBarAnimationDirection tempDirection = self.animationDirection;
    self.animationDirection = direction;
    [self dismissAnimated:animated completion:^{
        if (completion) {
            completion();
        }
        self.animationDirection = tempDirection;
    }];
}

- (void)dismissDismissBackgroundButtonAnimated:(BOOL)animated
{
    if (!_dismissBackgroundButton) {
        return;
    }
    if (!self.enableDismissMask) {
        return;
    }
    if (animated) {
        [UIView animateWithDuration:kDefaultDuration animations:^{
            self.dismissBackgroundButton.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.dismissBackgroundButton removeFromSuperview];
        }];
    } else {
        [self.dismissBackgroundButton removeFromSuperview];
    }
}

- (void)showDismissBackgroundButtonAnimated:(BOOL)animated
{
    if (!self.enableDismissMask) {
        return;
    }
    [self setupDismissMask];
    if (animated) {
        [UIView animateWithDuration:kDefaultDuration animations:^{
            self.dismissBackgroundButton.alpha = kDismissViewAlpha;
        }];
    } else {
        self.dismissBackgroundButton.alpha = kDismissViewAlpha;
    }
}

- (void)expandAnimated:(BOOL)animated expand:(BOOL)expand
{
    if (self.expanded == expand) {
        return;
    }
    CGRect newFrame = self.frame;
    CATransform3D detailContentViewTransform;
    if (expand) {
        //expand
        [self stopDismissTimer];
        newFrame.size.height = self.expandHeight;
        detailContentViewTransform = CATransform3DIdentity;
    } else {
        //fold
        newFrame.size.height = self.foldHeight;
        detailContentViewTransform = CATransform3DMakeScale(1.0, 0.01, 1.0);
    }
    if (animated) {
        [UIView animateWithDuration:kDefaultDuration animations:^{
            self.frame = newFrame;
            self.detailContentView.layer.transform = detailContentViewTransform;
        } completion:nil];
    } else {
        self.frame = newFrame;
        self.detailContentView.layer.transform = detailContentViewTransform;
    }
    self.expanded = expand;
}

- (void)toggleAnimated:(BOOL)animated
{
    if (self.expanded) {
        [self initDismissTimer];
        [self dismissDismissBackgroundButtonAnimated:animated];
    } else {
        [self showDismissBackgroundButtonAnimated:animated];
    }
    [self expandAnimated:YES expand:!self.expanded];
}

#pragma mark - private -
- (void)initKVO
{
    [self.titleLabel addObserver:self 
           forKeyPath:NSStringFromSelector(@selector(text)) 
              options:NSKeyValueObservingOptionNew 
              context:nil];
    [self.detailLabel addObserver:self 
           forKeyPath:NSStringFromSelector(@selector(text)) 
              options:NSKeyValueObservingOptionNew 
              context:nil];
}

- (void)initObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientationChanged:(NSNotification *)notification {    
    //reset self frame
    CGRect bounds = [UIWindow mainWindow].bounds;
    [self setupFrame];
    if (self.isShow) {
        self.isShow = NO;
        [self showAnimated:NO completion:nil];
    }
    
    //reset dismissBackgroundButtonFrame
    if (self.dismissBackgroundButton) {
        [UIView animateWithDuration:0.1 animations:^{
            self.dismissBackgroundButton.frame = self.superview.bounds;
        }];
    }
}

- (void)initDismissTimer
{
    if (self.dismissTimer) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.dismissTimer = [NSTimer bk_scheduledTimerWithTimeInterval:self.duration block:^(NSTimer *timer) {
        [weakSelf dismissAnimated:YES completion:nil];
        [weakSelf stopDismissTimer];
    } repeats:NO];
}

- (void)stopDismissTimer
{
    [self.dismissTimer invalidate];
    self.dismissTimer = nil;
}

- (void)setup
{
    self.clipsToBounds = YES;
    self.layer.cornerRadius = kRadius;
    [self addSubvews];
    [self setupFrame];
}

- (void)setFrame:(CGRect)frame 
       transform:(CATransform3D)transform 
           alpha:(CGFloat)alpha
        animated:(BOOL)animated 
      completion:(void (^)())completion
{
    if (!animated) {
        if (self.animationDirection != BUKMessageBarAnimationDirectionZ) {
            self.frame = frame;
        } else {
            self.alpha = alpha;
            self.layer.transform = transform;
        }
        if (completion) {
            completion();        
        }
        return;
    }
    
    [UIView animateWithDuration:kDefaultDuration animations:^{
        if (self.animationDirection != BUKMessageBarAnimationDirectionZ) {
            self.frame = frame;
        } else {
            self.alpha = alpha;
            self.layer.transform = transform;
        }
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)addSubvews
{
    [self.titleContainerView addSubview:self.titleLabel];
    [self.titleContainerView addSubview:self.subtitleLabel];    
    [self.detailContentView addSubview:self.detailLabel];
    
    [self addSubview:self.titleContainerView];
    [self addSubview:self.detailContentView];
    
    if (self.buttons.count) {
        [self.detailContentView addSubview:self.buttonsContainerView];
        [self addButtons];
    }
}

- (void)addButtons
{
    for (UIButton *button in self.buttons) {
        [self.buttonsContainerView addSubview:button];
    }
}

- (void)setupFrame
{
    CGFloat width = CGRectGetWidth([UIWindow mainWindow].bounds) - 2 * kPadding;
    
    CGRect titleBoundRect = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds) - 4 * kPadding - kTopButtonWidth * 2, CGRectGetHeight([UIScreen mainScreen].bounds));
    CGRect textBoundRect = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds) - 4 * kPadding, CGRectGetHeight([UIScreen mainScreen].bounds));
    CGPoint origin = CGPointMake(kPadding, kPadding + self.startY);
    CGRect titleFrame = [self.titleLabel textRectForBounds:titleBoundRect limitedToNumberOfLines:0];    
    titleFrame.origin.y = CGRectGetHeight(titleFrame) / 4;
    titleFrame.origin.x = kPadding;
    
    self.subtitleLabel.frame = CGRectMake(CGRectGetMaxX(titleFrame) + kPadding, 
                                          titleFrame.origin.y, 
                                          width - kPadding * 3 - CGRectGetWidth(titleFrame), 
                                          CGRectGetHeight(titleFrame));
    
    self.titleLabel.frame = titleFrame;
    CGRect titleContainerFrame = CGRectMake(0, 0, width, CGRectGetHeight(titleFrame) * 1.5);
    self.titleContainerView.frame = titleContainerFrame;
    [self setupTitleBackgroundLayerWithFrame:titleContainerFrame];
    
    
    CGRect detailFrame = [self.detailLabel textRectForBounds:textBoundRect limitedToNumberOfLines:0];
    detailFrame.origin.y = kPadding / 2;
    detailFrame.origin.x = kPadding;    
    self.detailLabel.frame = detailFrame;
    
    CGFloat detailContentViewHeight = CGRectGetHeight(detailFrame) + kPadding;
    if (self.buttons.count) {
        self.buttonsContainerView.frame = CGRectMake(0, CGRectGetMaxY(detailFrame) + kPadding / 2, width, kButtonContainerHeight);
        detailContentViewHeight += CGRectGetHeight(self.buttonsContainerView.frame); 
        CGFloat buttonWidth = (width - kButtonSpace * (self.buttons.count + 1)) / self.buttons.count;
        [self.buttons enumerateObjectsUsingBlock:^(BUKMessageBarButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGRect buttonFrame = CGRectMake(idx * buttonWidth + kButtonSpace * (idx + 1), kButtonTopPadding, buttonWidth, kButtonContainerHeight - kButtonTopPadding * 2);
            obj.bar = self;
            obj.frame = buttonFrame;
        }];
    }
    
    
    CGFloat height = CGRectGetHeight(titleContainerFrame) + detailContentViewHeight;
    self.detailContentView.frame = CGRectMake(0, CGRectGetHeight(titleContainerFrame), width, detailContentViewHeight);
    self.frame = CGRectMake(kPadding, -height, width, height);
    self.expandHeight = height;
    self.foldHeight = CGRectGetHeight(titleContainerFrame);
    if (!self.expanded) {
        self.expanded = YES;
        [self expandAnimated:NO expand:NO];
    }
}

- (void)setupTitleBackgroundLayerWithFrame:(CGRect)frame
{
    if (!_titleBackgroundLayer) {
        _titleBackgroundLayer = [CAShapeLayer layer];
    }
    _titleBackgroundLayer.frame = frame;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame 
                                 byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight 
                                       cornerRadii:CGSizeMake(kRadius, kRadius)];
    _titleBackgroundLayer.path = path.CGPath;
    switch (self.type) {
        case BUKMessageBarTypeSuccess:
            _titleBackgroundLayer.fillColor = [UIColor buk_tb_successColor].CGColor;
            break;
        case BUKMessageBarTypeFailed:
            _titleBackgroundLayer.fillColor = [UIColor buk_tb_failedColor].CGColor;
            break;
        case BUKMessageBarTypeInfo:
            _titleBackgroundLayer.fillColor = [UIColor buk_tb_infoColor].CGColor;
            break;
        case BUKMessageBarTypeLight:
            _titleBackgroundLayer.fillColor = [UIColor buk_tb_lightColor].CGColor;
            break;
    }
    [self.layer insertSublayer:_titleBackgroundLayer atIndex:0];
}

- (void)endPan
{
    CGSize superviewSize = self.superview.frame.size;
    if (CGRectGetMidX(self.frame) < superviewSize.width / 3 || CGRectGetMidX(self.frame) > superviewSize.width * 2 / 3) {
        //dismiss
        CGRect dismissFrame = self.frame;
        if (CGRectGetMidX(self.frame) < superviewSize.width / 3 ) {
            dismissFrame.origin.x = -CGRectGetWidth(dismissFrame);
        } else {
            dismissFrame.origin.x = CGRectGetWidth(self.superview.bounds) + CGRectGetWidth(dismissFrame);
        }
        
        [self setFrame:dismissFrame
             transform:CATransform3DMakeTranslation(0, 0, kZHeight) 
                 alpha:0.0
              animated:YES completion:^{
                  [self removeFromSuperview];
              }];
        [self dismissDismissBackgroundButtonAnimated:YES];
    } else {
        //bounce back
        CGRect frame = self.bounds;
        frame.origin.y = self.startY;
        frame.origin.x = kPadding;
        [UIView animateWithDuration:kDefaultDuration animations:^{
            self.frame = frame;
        }];
    }
}
- (void)setupDismissMask
{
    if (self.superview && self.enableDismissMask) {
        
        [self.superview insertSubview:self.dismissBackgroundButton belowSubview:self];
        self.dismissBackgroundButton.frame = self.superview.bounds; 
    }
}

- (CGFloat)navigationControllerHeight:(UIViewController *)vc
{
    if ([vc isKindOfClass:[UINavigationController class]]) {
        if (!((UINavigationController *)vc).isNavigationBarHidden) {
            return CGRectGetHeight(((UINavigationController *)vc).navigationBar.frame);
        }
    } else if (vc.navigationController && !vc.navigationController.isNavigationBarHidden) {
        return CGRectGetHeight(vc.navigationController.navigationBar.frame);
    }
    return 0.0;
}
#pragma mark - getters & setters -
#pragma mark - setters
- (void)setType:(BUKMessageBarType)type
{
    _type = type;
    [self setupTitleBackgroundLayerWithFrame:self.titleContainerView.frame];
}

- (void)setTapHandler:(void (^)(BUKMessageBar *))tapHandler
{
    _tapHandler = tapHandler;
    __weak typeof(self) weakSelf = self;
    self.tap = [UITapGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        weakSelf.previousPanPoint = [sender locationInView:[UIWindow mainWindow]];
        if (weakSelf.tapHandler) {
            weakSelf.tapHandler(weakSelf);
        }
    }];
    [self addGestureRecognizer:self.tap];
}

- (void)setButtons:(NSArray<BUKMessageBarButton *> *)buttons
{
    _buttons = buttons;
    [self addSubvews];
    [self setupFrame];
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.backgroundColor = color;
    _titleContainerView.backgroundColor = color;
    _detailContentView.backgroundColor = color;
}

#pragma mark - getters
- (CGFloat)smartY
{
    if (self.smartYTemp > 0) {
        return self.smartYTemp;
    }
    UIViewController *vc = [UIViewController topMostViewController];
    self.smartYTemp = kStatusBarHeight;
    CGFloat navigationBarHeight = [self navigationControllerHeight:vc];
    if (navigationBarHeight != 0.0) {
        self.smartYTemp += navigationBarHeight + kPadding;
    } else {
        self.smartYTemp += kPadding;
    }
    return self.smartYTemp;
}

- (CGFloat)startY
{
    if (self.enableSmartY) {
        return [self smartY];
    } else {
        return kStatusBarHeight;
    }
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.font = [UIFont fontWithName:@"Avenir-Light" size:16];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel
{
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.textColor = [UIColor grayColor];
        _subtitleLabel.textAlignment = NSTextAlignmentRight;
        _subtitleLabel.font = [UIFont fontWithName:@"Avenir-Light" size:12];
        _subtitleLabel.numberOfLines = 1;
    }
    return _subtitleLabel;
}

- (UILabel *)detailLabel
{
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textColor = [UIColor blackColor];
        _detailLabel.font = [UIFont fontWithName:@"Avenir-Light" size:11];
        _detailLabel.numberOfLines = 0;
    }
    return _detailLabel;
}

- (UIView *)titleContainerView
{
    if (!_titleContainerView) {
        _titleContainerView = [[UIView alloc] init];
    }
    return _titleContainerView;
}

- (UIView *)buttonsContainerView
{
    if (!_buttonsContainerView) {
        _buttonsContainerView = [[UIView alloc] init];
    }
    return _buttonsContainerView;
}

- (UIView *)detailContentView
{
    if (!_detailContentView) {
        _detailContentView = [[UIView alloc] init];
        _detailContentView.layer.anchorPoint = CGPointMake(0.5, 0);
        _detailContentView.backgroundColor = [UIColor buk_messageBar_background];
    }
    return _detailContentView;
}

- (UIColor *)color
{
    if (!_color) {
        _color = [UIColor buk_messageBar_background]; 
    }
    return _color;
}

- (UIButton *)dismissBackgroundButton
{
    if (!_dismissBackgroundButton) {
        _dismissBackgroundButton = [[UIButton alloc] init];
        _dismissBackgroundButton.backgroundColor = [UIColor blackColor];
        _dismissBackgroundButton.alpha = 0.0;
        __weak typeof(self) weakSelf = self;
        [_dismissBackgroundButton bk_addEventHandler:^(id sender) {
            [weakSelf dismissAnimated:YES completion:^{
                [weakSelf.dismissBackgroundButton removeFromSuperview];
            }];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissBackgroundButton;
}
@end
