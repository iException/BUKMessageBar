//
//  MZGoogleStyleButton.h
//  Pods
//
//  Created by Monzy Zhang on 5/12/16.
//
//

#import <UIKit/UIKit.h>

@interface MZGoogleStyleButton : UIButton
@property (nonatomic) CGFloat layerOpaque;
@property (nonatomic) UIColor *layerColor;
@property (nonatomic) CGFloat duration;

- (instancetype)initWithDuration:(CGFloat)duration;
- (instancetype)initWithLayerOpaque:(CGFloat)layerOpaque;
- (instancetype)initWithLayerColor:(UIColor *)layerColor;
- (instancetype)initWithDuration:(CGFloat)duration
                     layerOpaque:(CGFloat)layerOpaque
                      layerColor:(UIColor *)layerColor;
@end
