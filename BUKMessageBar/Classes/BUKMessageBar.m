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

@interface BUKMessageBar ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIView *titleContainerView;
@property (nonatomic, strong) UIView *buttonsContainerView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) CAShapeLayer *titleBackgroundLayer;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIButton *dismissButton;
@property (nonatomic, assign) CGFloat expandHeight;
@property (nonatomic, assign) CGFloat foldHeight;
@property (nonatomic, assign) CGPoint previousPanPoint;

@end

@implementation BUKMessageBar

#pragma mark - lifecycle -
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.type = BUKMessageBarTypeLight;
        self.animationDirection = BUKMessageBarAnimationDirectionDirectionY;
        self.duration = kDefaultDuration;
        self.expanded = NO;
        [self addGestureRecognizer:[UIPanGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (!self.superview) {
                return;
            }
            CGPoint locationInMainWindow = [sender locationInView:self.superview];
            CGRect frame = self.frame;
            switch (state) {
                case UIGestureRecognizerStateChanged: {
                    frame.origin.x += locationInMainWindow.x - self.previousPanPoint.x;
                    self.frame = frame;
                    break;
                }
                case UIGestureRecognizerStateCancelled:
                case UIGestureRecognizerStateFailed:
                case UIGestureRecognizerStateEnded: {
                    [self endPan];
                    break;
                }
                default:
                    break;
            }
            self.previousPanPoint = locationInMainWindow;
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
    [self.titleLabel removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
    [self.detailLabel removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
}

#pragma mark - kvo -
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ((object == self.titleLabel && keyPath == NSStringFromSelector(@selector(text))) || (object == self.detailLabel && keyPath == NSStringFromSelector(@selector(text)))) {
        [self setupFrame];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - public -
- (void)showAnimated:(BOOL)animated completion:(void (^)())completion
{
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
        case BUKMessageBarAnimationDirectionDirectionY:{
            currentFrame.origin.y = -CGRectGetHeight(currentFrame);
            break;
        }
        case BUKMessageBarAnimationDirectionDirectionXPlus:{
            currentFrame.origin.y = kStatusBarHeight;
            currentFrame.origin.x = -CGRectGetWidth(currentFrame);
            break;
        }
        case BUKMessageBarAnimationDirectionDirectionXNegative:{
            currentFrame.origin.y = kStatusBarHeight;
            currentFrame.origin.x = CGRectGetWidth([UIScreen mainScreen].bounds) + CGRectGetWidth(currentFrame);
            break;
        }
        case BUKMessageBarAnimationDirectionDirectionZ:{
            currentFrame.origin.y = kStatusBarHeight;
            currentFrame.origin.x = kPadding;
            CATransform3D transform = CATransform3DMakeTranslation(0, 0, kZHeight);
            transform.m34 = -1.0 / 500.0;
            self.layer.transform = transform;
            self.alpha = 0.0;
            break;
        }
    }
    self.frame = currentFrame;
    frame.origin.y = kStatusBarHeight;
    frame.origin.x = kPadding;
    [self setFrame:frame 
         transform:CATransform3DIdentity 
             alpha:1.0 
          animated:animated 
        completion:completion];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)())completion
{
    if (!self.isShow) {
        return;
    }
    CATransform3D transform = CATransform3DIdentity;
    CGFloat alpha = 1.0;
    if (self.animationDirection == BUKMessageBarAnimationDirectionDirectionZ) {
        transform = CATransform3DMakeTranslation(0, 0, kZHeight);
        alpha = 0.0;
    }
    self.isShow = false;
    CGRect frame = self.bounds;

    switch (self.animationDirection) {
        case BUKMessageBarAnimationDirectionDirectionY:{
            frame.origin.y = -CGRectGetHeight(frame);
            frame.origin.x += kPadding;
            break;
        }
        case BUKMessageBarAnimationDirectionDirectionXPlus:{
            frame.origin.y = kStatusBarHeight;
            frame.origin.x = -CGRectGetWidth(frame);
            break;
        }
        case BUKMessageBarAnimationDirectionDirectionXNegative:{
            frame.origin.y = kStatusBarHeight;
            frame.origin.x = CGRectGetWidth([UIScreen mainScreen].bounds) + CGRectGetWidth(frame);
            break;
        }
        case BUKMessageBarAnimationDirectionDirectionZ:{            
            transform = CATransform3DMakeTranslation(0, 0, kZHeight);
            transform.m34 = -1.0 / 500.0;
            alpha = 0.0;
            break;
        }
    }

    [self setFrame:frame
         transform:transform 
             alpha:alpha
          animated:animated completion:^{
        if (completion) {
            completion();
        }
        [self removeFromSuperview];
    }];
}

- (void)expandAnimated:(BOOL)animated expand:(BOOL)expand
{
    if (self.expanded == expand) {
        return;
    }
    CGRect newFrame = self.frame;
    CATransform3D contentViewTransform;
    if (expand) {
        //expand
        newFrame.size.height = self.expandHeight;
        contentViewTransform = CATransform3DIdentity;
    } else {
        //fold
        newFrame.size.height = self.foldHeight;
        contentViewTransform = CATransform3DMakeScale(1.0, 0.01, 1.0);
    }
    if (animated) {
        [UIView animateWithDuration:self.duration animations:^{
            self.frame = newFrame;
            self.contentView.layer.transform = contentViewTransform;
        } completion:nil];
    } else {
        self.frame = newFrame;
        self.contentView.layer.transform = contentViewTransform;
    }
    self.expanded = expand;
}

- (void)toggleAnimated:(BOOL)animated
{
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
    //mainly rotate
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
        if (self.animationDirection != BUKMessageBarAnimationDirectionDirectionZ) {
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
    [UIView animateWithDuration:self.duration animations:^{
        if (self.animationDirection != BUKMessageBarAnimationDirectionDirectionZ) {
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
    [self.contentView addSubview:self.detailLabel];
    
    [self addSubview:self.titleContainerView];
    [self addSubview:self.contentView];
    
    if (self.buttons.count) {
        [self.contentView addSubview:self.buttonsContainerView];
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
    CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds) - 2 * kPadding;
    
    CGRect titleBoundRect = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds) - 4 * kPadding - kTopButtonWidth * 2, CGRectGetHeight([UIScreen mainScreen].bounds));
    CGRect textBoundRect = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds) - 4 * kPadding, CGRectGetHeight([UIScreen mainScreen].bounds));
    CGPoint origin = CGPointMake(kPadding, kPadding + kStatusBarHeight);
    CGRect titleFrame = [self.titleLabel textRectForBounds:titleBoundRect limitedToNumberOfLines:0];    
    titleFrame.origin.y = CGRectGetHeight(titleFrame) / 4;
    titleFrame.origin.x = kPadding;
    
    self.subtitleLabel.frame = CGRectMake(CGRectGetMaxX(titleFrame) + kPadding, 
                                          titleFrame.origin.y, 
                                          width - kPadding * 3 - CGRectGetWidth(titleFrame), 
                                          CGRectGetHeight(titleFrame));
    
    self.titleLabel.frame = titleFrame;
//    self.toggleButton.frame = CGRectMake(width - kTopButtonWidth * 2 - kPadding, CGRectGetHeight(titleFrame) / 4, kTopButtonWidth, CGRectGetHeight(titleFrame));
//    self.dismissButton.frame = CGRectMake(width - kTopButtonWidth - kPadding, CGRectGetHeight(titleFrame) / 4, kTopButtonWidth, CGRectGetHeight(titleFrame));
    CGRect titleContainerFrame = CGRectMake(0, 0, width, CGRectGetHeight(titleFrame) * 1.5);
    self.titleContainerView.frame = titleContainerFrame;
    [self setupTitleBackgroundLayerWithFrame:titleContainerFrame];
    
    
    CGRect detailFrame = [self.detailLabel textRectForBounds:textBoundRect limitedToNumberOfLines:0];
    detailFrame.origin.y = kPadding / 2;
    detailFrame.origin.x = kPadding;    
    self.detailLabel.frame = detailFrame;
    
    CGFloat contentViewHeight = CGRectGetHeight(detailFrame) + kPadding;
    if (self.buttons.count) {
        self.buttonsContainerView.frame = CGRectMake(0, CGRectGetMaxY(detailFrame) + kPadding / 2, width, kButtonContainerHeight);
        contentViewHeight += CGRectGetHeight(self.buttonsContainerView.frame); 
        CGFloat buttonWidth = (width - kButtonSpace * (self.buttons.count + 1)) / self.buttons.count;
        [self.buttons enumerateObjectsUsingBlock:^(BUKMessageBarButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGRect buttonFrame = CGRectMake(idx * buttonWidth + kButtonSpace * (idx + 1), kButtonTopPadding, buttonWidth, kButtonContainerHeight - kButtonTopPadding * 2);
            obj.bar = self;
            obj.frame = buttonFrame;
        }];
    }
    
    
    CGFloat height = CGRectGetHeight(titleContainerFrame) + contentViewHeight;
    self.contentView.frame = CGRectMake(0, CGRectGetHeight(titleContainerFrame), width, contentViewHeight);
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
    } else {
        //bounce back
        CGRect frame = self.bounds;
        frame.origin.y = kStatusBarHeight;
        frame.origin.x = kPadding;
        [UIView animateWithDuration:self.duration animations:^{
            self.frame = frame;
        }];
    }
}

#pragma mark - getters & setters -
#pragma mark - setters
- (void)setExpanded:(BOOL)expanded
{
    _expanded = expanded;
    if (_expanded) {
        [self.toggleButton setTitle:kFoldButtonTitle forState:UIControlStateNormal];
    } else {
        [self.toggleButton setTitle:kExpandButtonTitle forState:UIControlStateNormal];
    }
}

- (void)setType:(BUKMessageBarType)type
{
    _type = type;
    [self setupTitleBackgroundLayerWithFrame:self.titleContainerView.frame];
}

- (void)setTapHandler:(void (^)(BUKMessageBar *))tapHandler
{
    _tapHandler = tapHandler;
    self.tap = [UITapGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        self.previousPanPoint = [sender locationInView:[UIWindow mainWindow]];
        if (_tapHandler) {
            _tapHandler(self);
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

#pragma mark - getters
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

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.layer.anchorPoint = CGPointMake(0.5, 0);
        _contentView.backgroundColor = [UIColor buk_messageBar_background];
    }
    return _contentView;
}

- (UIButton *)toggleButton
{
    if (!_toggleButton) {
        _toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _toggleButton.hidden = YES;
        if (_type == BUKMessageBarTypeLight) {
            [_toggleButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        } else {
            [_toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        _toggleButton.titleLabel.font = [UIFont systemFontOfSize:10];
        
        __weak typeof(self) weakSelf = self;
        [_toggleButton bk_addEventHandler:^(id sender) {
            [weakSelf expandAnimated:YES expand:!self.expanded];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _toggleButton;
}

- (UIButton *)dismissButton
{
    if (!_dismissButton) {
        _dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _dismissButton.hidden = YES;
        if (_type == BUKMessageBarTypeLight) {
            [_dismissButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        } else {
            [_dismissButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        [_dismissButton setTitle:@"关闭" forState:UIControlStateNormal];
        _dismissButton.titleLabel.font = [UIFont systemFontOfSize:10];
        
        __weak typeof(self) weakSelf = self;
        [_dismissButton bk_addEventHandler:^(id sender) {
            [weakSelf dismissAnimated:YES completion:nil];            
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissButton;
}
@end
