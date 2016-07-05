# BUKMessageBar

[![CI Status](http://img.shields.io/travis/monzy613/BUKMessageBar.svg?style=flat)](https://travis-ci.org/monzy613/BUKMessageBar)
[![Version](https://img.shields.io/cocoapods/v/BUKMessageBar.svg?style=flat)](http://cocoapods.org/pods/BUKMessageBar)
[![License](https://img.shields.io/cocoapods/l/BUKMessageBar.svg?style=flat)](http://cocoapods.org/pods/BUKMessageBar)
[![Platform](https://img.shields.io/cocoapods/p/BUKMessageBar.svg?style=flat)](http://cocoapods.org/pods/BUKMessageBar)


## Snapshots
![img](http://o7b20it1b.bkt.clouddn.com/bukmessagebar_fold.png)
![img](http://o7b20it1b.bkt.clouddn.com/bukmessagebar_expanded.png)

## Example
```objc
BUKMessageBar *bar = [[BUKMessageBar alloc] initWithTitle:@"title" detail:@"detail"];

bar.animationDirection = BUKMessageBarAnimationDirectionDirectionZ;

bar.buttons = @[
    [BUKMessageBarButton buttonWithTitle:@"OK" type:BUKMessageBarButtonTypeOk handler:^(BUKMessageBarButton *button) {
        [button.bar dismissAnimated:YES completion:nil];  
    }]
];

[bar setTapHandler:^(BUKMessageBar *bar) {
    [bar toggleAnimated:YES];
}];

[bar showAnimated:YES completion:nil];
```


To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

BUKMessageBar is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BUKMessageBarManager", :git => 'https://github.com/iException/BUKMessageBarManager.git'
```

## Author

monzy613, monzy613@gmail.com

## License

BUKMessageBar is available under the MIT license. See the LICENSE file for more info.
