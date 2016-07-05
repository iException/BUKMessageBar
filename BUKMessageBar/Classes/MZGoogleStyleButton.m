//
//  MZGoogleStyleButton.m
//  Pods
//
//  Created by Monzy Zhang on 5/12/16.
//
//

#import "MZGoogleStyleButton.h"
@interface MZGoogleStyleButton ()
@property (nonatomic, strong) CALayer *circleLayer;
@property (nonatomic) BOOL isPreviousTouchInside;
@property (nonatomic) BOOL animating;
@end

@implementation MZGoogleStyleButton

#pragma mark - initializers
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.layer addSublayer:self.circleLayer];
        self.layerOpaque = 0.6;
        self.duration = 0.3;
        self.layerColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
    }
    return self;
}

- (instancetype)initWithDuration:(CGFloat)duration
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self.layer addSublayer:self.circleLayer];
        self.layerOpaque = 0.6;
        self.duration = duration;
        self.layerColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
    }
    return self;
}

- (instancetype)initWithLayerOpaque:(CGFloat)layerOpaque
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self.layer addSublayer:self.circleLayer];
        self.layerOpaque = layerOpaque;
        self.duration = 0.3;
        self.layerColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
    }
    return self;
}

- (instancetype)initWithLayerColor:(UIColor *)layerColor
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self.layer addSublayer:self.circleLayer];
        self.layerOpaque = 0.6;
        self.duration = 0.3;
        self.layerColor = layerColor;
        self.clipsToBounds = YES;
    }
    return self;
}

- (instancetype)initWithDuration:(CGFloat)duration
                     layerOpaque:(CGFloat)layerOpaque
                      layerColor:(UIColor *)layerColor
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self.layer addSublayer:self.circleLayer];
        self.duration = duration;
        self.layerOpaque = layerOpaque;
        self.layerColor = layerColor;
        self.clipsToBounds = YES;
    }
    return self;
}

#pragma mark - touch events
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    CGPoint touchPoint = [touches.anyObject locationInView:self];
    [self enlargeFromPoint: touchPoint];
    self.isPreviousTouchInside = self.isTouchInside;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    CGPoint touchPoint = [touches.anyObject locationInView:self];
    if (self.isTouchInside && !self.isPreviousTouchInside) {
        [self enlargeFromPoint:touchPoint];
    } else if (!self.isTouchInside && self.isPreviousTouchInside){
        [self endAnimation];
    }
    self.isPreviousTouchInside = self.isTouchInside;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (![self isPointInView:[touches.anyObject locationInView:self] view:self] || self.animating == NO) {
        [self endAnimation];
    }
}

- (void)endAnimation
{
    self.circleLayer.opacity = 0.0;
    self.circleLayer.transform = CATransform3DIdentity;
}

- (void)enlargeFromPoint:(CGPoint)point
{
    self.animating = YES;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.circleLayer.opacity = self.layerOpaque;
    self.circleLayer.position = point;
    [CATransaction commit];
    [CATransaction setDisableActions:NO];


    CABasicAnimation *enlargeAnimation = [CABasicAnimation animation];
    enlargeAnimation.keyPath = @"transform";
    CGFloat radius = ceil([self radiusFromPoint:point]);
    enlargeAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(radius, radius, 1)];
    enlargeAnimation.duration = self.duration;
    enlargeAnimation.delegate = self;
    enlargeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.circleLayer addAnimation:enlargeAnimation forKey: nil];
    self.circleLayer.transform = CATransform3DMakeScale(radius, radius, 1);
}

#pragma mark - calayer delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    self.animating = NO;
    if (!self.isTouchInside) {
        [self endAnimation];
    }
}

#pragma mark - util methods
- (BOOL)isPointInView:(CGPoint)point view:(UIView *)view
{
    return
    (point.x <= CGRectGetWidth(view.bounds) && point.x >= 0) &&
    (point.y <= CGRectGetHeight(view.bounds) && point.y >= 0);
}

- (CGFloat)radiusFromPoint:(CGPoint)point
{
    CGFloat max = [self distance:point p2:self.bounds.origin];
    CGFloat new = [self distance:point p2:CGPointMake(0, CGRectGetHeight(self.bounds))];
    max = MAX(new, max);

    new = [self distance:point p2:CGPointMake(CGRectGetWidth(self.bounds), 0)];
    max = MAX(new, max);

    new = [self distance:point p2:CGPointMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    max = MAX(new, max);
    return max * 2;
}

- (CGFloat)distance:(CGPoint)p1 p2:(CGPoint)p2
{
    return sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
}

#pragma mark - getters & setters
- (CALayer *)circleLayer
{
    if (!_circleLayer) {
        _circleLayer = [CAShapeLayer layer];
        _circleLayer.frame = CGRectMake(0, 0, 1, 1);
        _circleLayer.cornerRadius = 0.5;
        _circleLayer.masksToBounds = YES;
    }
    return _circleLayer;
}

- (void)setLayerColor:(UIColor *)layerColor
{
    _layerColor = layerColor;
    _circleLayer.backgroundColor = _layerColor.CGColor;
}
@end
