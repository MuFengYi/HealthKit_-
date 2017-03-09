//
//  ViewController.h
//  TestHealthKit
//
//  Created by macro macro on 16/9/18.
//  Copyright © 2016年 macro macro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>
@interface ViewController : UIViewController
@property   (nonatomic,strong)HKHealthStore *healthStore;
@property (weak, nonatomic) IBOutlet UILabel *stepCountUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepCountValueLabel;

@end

