//
//  ViewController.h
//  CloudVisionTest
//
//  Created by MartinPham on 26/06/17.
//  Copyright © 2017 fornace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>


@interface ViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UITextView *debugTextView;

@end

