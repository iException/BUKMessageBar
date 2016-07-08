//
//  BUKViewController.m
//  BUKMessageBar
//
//  Created by monzy613 on 07/05/2016.
//  Copyright (c) 2016 monzy613. All rights reserved.
//

#import "BUKViewController.h"
#import "BUKMessageBar.h"

@interface BUKViewController ()

@property (nonatomic, strong) BUKMessageBar *bar;

@end

@interface BUKViewController ()

@end

@implementation BUKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)newMessage:(id)sender {
    
    BUKMessageBar *bar = [[BUKMessageBar alloc] initWithTitle:@"/Home" detail:@"asdasd asdasd asdas dasda sasdjlasjdl ajlsd lasdj la asdasd asdasd asdas dasda sasdjlasjdl ajlsd lasdj la "];
    bar.color = [UIColor redColor];
    bar.animationDirection = BUKMessageBarAnimationDirectionDirectionZ;
    bar.buttons = @[
                    [BUKMessageBarButton buttonWithTitle:@"OK" type:BUKMessageBarButtonTypeOk handler:^(BUKMessageBarButton *button) {
                        [button.bar dismissAnimated:YES completion:nil];  
                    }]
                    ];
    [bar setTapHandler:^(BUKMessageBar *bar) {
        [bar toggleAnimated:YES];
    }];
    [bar showAnimated:YES completion:^{
    }];
}

@end
