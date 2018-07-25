//
//  RCTAppleHealthKit+Methods_Body.m
//  RCTAppleHealthKit
//
//  Created by Greg Wilson on 2016-06-26.
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit+Methods_MyKeto.h"
#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"

@implementation RCTAppleHealthKit (Methods_MyKeto)


- (void)prestige_updateWeight:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{

    NSMutableArray *dataSources = [[NSMutableArray alloc] init];
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit poundUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    double weight = [RCTAppleHealthKit doubleValueFromOptions:input];
    HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:unit doubleValue:weight];
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:startDate endDate:endDate];
    
    HKSourceQuery *sourceQuery = [[HKSourceQuery alloc] initWithSampleType:weightType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error)                           {
        for (HKSource *source in sources)
        {
            if ([source.bundleIdentifier isEqualToString:@"com.prestigeworldwide.keto"])
            {
                [dataSources addObject:source];
                NSPredicate *datePredicate = [RCTAppleHealthKit predicateForSamplesBetweenDates:startDate endDate:endDate];
                NSPredicate *sourcesPredicate = [HKQuery predicateForObjectsFromSources:[NSSet setWithArray:dataSources]];
                NSArray *subPredicates = [[NSArray alloc] initWithObjects:sourcesPredicate, datePredicate, nil];
                NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
                
               HKSampleQuery *finalQuery = [[HKSampleQuery alloc] initWithSampleType:weightType predicate:compoundPredicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                    if( [results firstObject] != nil ){
                        
                        [self.healthStore deleteObject:[results firstObject] withCompletion:^(BOOL success, NSError * _Nullable error) {
                            RCTLogInfo(@"Successfully got results %@", results);
                            if (success) {
                                callback(@[[NSNull null], results]);
                                RCTLogInfo(@"Successfully deleted entry from health kit %@", results);
                            } else {
                                RCTMakeError(@"error deleting the weight sample", error, nil);
                            }
                        }];

                         [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {
                            if (!success) {
                                NSLog(@"error saving the weight sample: %@", error);
                                callback(@[RCTMakeError(@"error saving the weight sample", error, nil)]);
                            }
                            RCTLogInfo(@"Successfully Saved Weight %@", weightSample);
                        }];

                        return;
                    } else {
                        NSLog(@"error getting weight samples: %@", error);
                        callback(@[RCTMakeError(@"no weight samples found for this date", nil, nil)]);
                        return;
                    }
                }];
                 [self.healthStore executeQuery:finalQuery];
            }
        }
    }];
    [self.healthStore executeQuery:sourceQuery];

}


@end
