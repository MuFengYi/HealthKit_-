//
//  ViewController.m
//  TestHealthKit
//
//  Created by macro macro on 16/9/18.
//  Copyright © 2016年 macro macro. All rights reserved.
//

#import "ViewController.h"
#import "NSDate+Category.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.healthStore    =   [[HKHealthStore alloc]init];
    

    if ([HKHealthStore isHealthDataAvailable])
    {
        NSSet *writeDataTypes = [self dataTypesToWrite];
        
        NSSet *readDataTypes = [self dataTypesToRead];
        
        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            
            
            if (!success) {
                
                NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                
                
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self updateStepCountLabel];
                
            });
            
        }];
    }
//    [self updateStepCountLabel];
}
- (NSSet *)dataTypesToWrite
{
    HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed]; // 膳食能量
    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]; // 活动能量
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]; // 身高
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]; // 体重
    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]; // 步数
    
    HKQuantityType  *mindfulType    =    (HKQuantityType*) [HKQuantityType categoryTypeForIdentifier:HKCategoryTypeIdentifierMindfulSession];//正念
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, stepCountType, mindfulType,nil];
}

// 读取数据
- (NSSet *)dataTypesToRead
{
    HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed]; // 膳食能量
    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned]; // 活动能量
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]; // 身高
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]; // 体重
    HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth]; // 出生日期
    HKCharacteristicType *biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex]; // 性别
    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]; // 步数
    
    HKQuantityType  *mindfulType    =  (HKQuantityType*) [HKQuantityType categoryTypeForIdentifier:HKCategoryTypeIdentifierMindfulSession];
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalSexType, stepCountType, mindfulType,nil];
}


- (void)updateStepCountLabel
{
        self.stepCountUnitLabel.text = @"步数 (健康+App步)";
        self.stepCountValueLabel.text = @"0";
    
    HKQuantityType *stepCountType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    //NSSortDescriptors用来告诉healthStore怎么样将结果排序。
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    // 当天时间段
    NSPredicate *todayPredicate = [self predicateForSamplesToday];
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:stepCountType predicate:todayPredicate limit:HKObjectQueryNoLimit sortDescriptors:@[start, end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        //打印查询结果
        NSLog(@"resultCount = %ld result = %@",results.count,results);
        double deviceStepCounts = 0.f;
        double appStepCounts = 0.f;
        for (HKQuantitySample *result in results) {
            HKQuantity *quantity = result.quantity;
            HKUnit *stepCount = [HKUnit countUnit];
            double count = [quantity doubleValueForUnit:stepCount];
            // 实例数据
            //            "50 count \"Fit\" (1) 2016-07-11 17:43:03 +0800 2016-07-11 17:43:03 +0800",
            //            "26 count \"你的设备名\" (9.3.1) \"iPhone\" 2016-07-11 15:19:33 +0800 2016-07-11 15:19:41 +0800",
            
            //            26：result.quantity
            //            count：单位，还有其它kg、m等，不同单位使用不同HKUnit
            //            \"Fit\"：result.source.name
            //            (9.3.1)：result.device.softwareVersion，App写入的时候是空的
            //            \"iPhone\"：result.device.model
            //            2016-07-11 15:19:33 +0800：result.startDate
            //            2016-07-11 15:19:41 +0800：result.endDate
            
            
            // 区分手机自动计算步数和App写入的步数
            if ([result.source.name isEqualToString:[UIDevice currentDevice].name]) {
                // App写入的数据result.device.name为空
                if (result.device.name.length > 0) {
                    deviceStepCounts += count;
                }
                else {
                    appStepCounts += count;
                }
            }
            else {
                appStepCounts += count;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *deviceStepCountsString = [NSNumberFormatter localizedStringFromNumber:@(deviceStepCounts) numberStyle:NSNumberFormatterNoStyle];
            NSString *stepCountsString = [NSNumberFormatter localizedStringFromNumber:@(appStepCounts) numberStyle:NSNumberFormatterNoStyle];
            NSString *totalCountsString = [NSNumberFormatter localizedStringFromNumber:@(deviceStepCounts+appStepCounts) numberStyle:NSNumberFormatterNoStyle];
            
            NSString *text = [NSString stringWithFormat:@"%@+%@=%@", deviceStepCountsString, stepCountsString, totalCountsString];
                        self.stepCountValueLabel.text = text;
        });
        
    }];
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}

// 当天时间段
- (NSPredicate *)predicateForSamplesToday
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

- (void)saveStepCountIntoHealthStore:(double)stepCount
{
    // Save the user's step count into HealthKit.
    HKUnit *countUnit = [HKUnit countUnit];
    HKQuantity *countUnitQuantity = [HKQuantity quantityWithUnit:countUnit doubleValue:stepCount];
    
    HKQuantityType *countUnitType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSDate *now = [NSDate date];
    
    HKQuantitySample *stepCountSample = [HKQuantitySample quantitySampleWithType:countUnitType quantity:countUnitQuantity startDate:now endDate:now];
    
    [self.healthStore saveObject:stepCountSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"An error occured saving the step count sample %@. In your app, try to handle this gracefully. The error was: %@.", stepCountSample, error);
            abort();
        }
        
        [self updateStepCountLabel];
    }];
}

- (IBAction)writeMindfulData:(id)sender {
    HKUnit *countUnit = [HKUnit minuteUnit];
    
    HKQuantity *countUnitQuantity = [HKQuantity quantityWithUnit:countUnit doubleValue:5];
    
    HKCategoryType *mindfulCategoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierMindfulSession];
    
    NSDate *now = [NSDate date];
    
    NSDate  *hourNow    =   [NSDate dateWithMinutesBeforeNow:5];
    
    HKCategorySample *mindfulSample = [HKCategorySample categorySampleWithType:mindfulCategoryType value:0.25 startDate:hourNow endDate:now];
    
    [self.healthStore saveObject:mindfulSample withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"An error occured saving the step count sample %@. In your app, try to handle this gracefully. The error was: %@.", mindfulSample, error);
            abort();
        }
        
        [self updateStepCountLabel];
    }];

}
@end
