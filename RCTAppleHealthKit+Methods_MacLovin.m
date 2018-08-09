//
//  RCTAppleHealthKit+Methods_MacLovin.m
//  RCTAppleHealthKit
//
//  Created by Greg Wilson on 2016-06-26.
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit+Methods_MacLovin.h"
#import "RCTAppleHealthKit+Queries.h"
#import "RCTAppleHealthKit+Utils.h"

@implementation RCTAppleHealthKit (Methods_MacLovin)


- (void)maclovin_updateWeight:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    //If User has not authorized writing weight, return out of method
    if ([self.healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]] == HKAuthorizationStatusSharingDenied) {
        callback(@[RCTMakeError(@"AHK Deauthorized Weight", nil, nil)]);
        return;
    }
    
    //declare query variables and build weight sample to be saved
    NSMutableArray *dataSources = [[NSMutableArray alloc] init];
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKUnit *unit = [RCTAppleHealthKit hkUnitFromOptions:input key:@"unit" withDefault:[HKUnit poundUnit]];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSDate *saveDate = [RCTAppleHealthKit dateFromOptions:input key:@"finalDate" withDefault:[NSDate date]];
    double weight = [RCTAppleHealthKit doubleValueFromOptions:input];
    HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:unit doubleValue:weight];
    HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:saveDate endDate:saveDate];
    __block BOOL sourceFound = false;
    //run first query to get our app source
    HKSourceQuery *sourceQuery = [[HKSourceQuery alloc] initWithSampleType:weightType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error){
        for (HKSource *source in sources)
        {
            
            if ([source.bundleIdentifier isEqualToString:@"com.prestigeworldwide.maclovin"])
            {
                sourceFound = true;
                [dataSources addObject:source];
                NSPredicate *datePredicate = [RCTAppleHealthKit predicateForSamplesBetweenDates:startDate endDate:endDate];
                NSPredicate *sourcesPredicate = [HKQuery predicateForObjectsFromSources:[NSSet setWithArray:dataSources]];
                NSArray *subPredicates = [[NSArray alloc] initWithObjects:sourcesPredicate, datePredicate, nil];
                NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
                //run second query to get querey dates weight
                HKSampleQuery *finalQuery = [[HKSampleQuery alloc] initWithSampleType:weightType predicate:compoundPredicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                    if( [results firstObject] != nil ){
                        //If there was a weight sample saved at this date previously, delete it before saving new one
                        [self.healthStore deleteObject:[results firstObject] withCompletion:^(BOOL success, NSError * _Nullable error) {
                            if (!success) {
                                RCTMakeError(@"error deleting the previous weight sample deleteObject", error, nil);
                            }
                        }];
                    }
                    //save weight sample
                    [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {
                        if (!success) {
                            RCTMakeError(@"Error saving weight sample", error, nil);
                        }else{
                            callback(@[[NSNull null], @(weight)]);
                        }
                    }];
                    return;
                }];
                [self.healthStore executeQuery:finalQuery];
            }
        }
        
        //if no data ever saved for weight by myketo, save weight
        if([sources count] == 0 || sourceFound == false){
            [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {
                if (!success) {
                    RCTMakeError(@"error saving the weight sample with no sources", error, nil);
                }else{
                    callback(@[[NSNull null], @(weight)]);
                }
            }];
        }
        
    }];
    [self.healthStore executeQuery:sourceQuery];
}

- (void)maclovin_updateWater:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    
    //If User has not authorized writing water, return out of method
    if ([self.healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater]] == HKAuthorizationStatusSharingDenied) {
        callback(@[RCTMakeError(@"AHK Deauthorized Water", nil, nil)]);
        return;
    }
    
    //declare query variables and build water sample to be saved
    NSMutableArray *dataSources = [[NSMutableArray alloc] init];
    HKQuantityType *waterType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSDate *saveDate = [RCTAppleHealthKit dateFromOptions:input key:@"finalDate" withDefault:[NSDate date]];
    double waterValue = [RCTAppleHealthKit doubleValueFromOptions:input];
    __block BOOL sourceFound = false;
    HKQuantitySample* waterSample = [HKQuantitySample quantitySampleWithType:waterType
                                                                    quantity:[HKQuantity quantityWithUnit:[HKUnit literUnit] doubleValue:waterValue]
                                                                   startDate:saveDate
                                                                     endDate:saveDate
                                                                    metadata:nil];
    
    //run first query to get our app source
    HKSourceQuery *sourceWaterQuery = [[HKSourceQuery alloc] initWithSampleType:waterType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error){
        
        for (HKSource *source in sources)
        {
            if ([source.bundleIdentifier isEqualToString:@"com.prestigeworldwide.maclovin"])
            {
                sourceFound = true;
                [dataSources addObject:source];
                NSPredicate *datePredicate = [RCTAppleHealthKit predicateForSamplesBetweenDates:startDate endDate:endDate];
                NSPredicate *sourcesPredicate = [HKQuery predicateForObjectsFromSources:[NSSet setWithArray:dataSources]];
                NSArray *subPredicates = [[NSArray alloc] initWithObjects:sourcesPredicate, datePredicate, nil];
                NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
                //run second query to get querey date's water entry
                HKSampleQuery *updateWaterQuery = [[HKSampleQuery alloc] initWithSampleType:waterType predicate:compoundPredicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                    if( [results firstObject] != nil ){
                        //If there was a previously saved water sample on this date, delete it
                        [self.healthStore deleteObject:[results firstObject] withCompletion:^(BOOL success, NSError * _Nullable error) {
                            if (!success) {
                                RCTMakeError(@"error deleting the water sample", error, nil);
                            }
                        }];
                    }
                    //Save the new water sample, regardless of deletion or not
                    [self.healthStore saveObject:waterSample withCompletion:^(BOOL success, NSError *error) {
                        if (!success) {
                            callback(@[RCTMakeError(@"error saving the water sample with previous app sources", error, nil)]);
                        }else{
                            callback(@[[NSNull null], @(waterValue)]);
                        }
                    }];
                    return;
                    
                }];
                [self.healthStore executeQuery:updateWaterQuery];
            }
        }
        
        //if no data ever saved for water in  user's HealthKit, save water
        if([sources count] == 0 || sourceFound == false){
            [self.healthStore saveObject:waterSample withCompletion:^(BOOL success, NSError *error) {
                if (!success) {
                    callback(@[RCTMakeError(@"error saving the water sample with no total sources", error, nil)]);
                }else{
                    callback(@[[NSNull null], @(waterValue)]);
                }
            }];
        }
        
    }];
    [self.healthStore executeQuery:sourceWaterQuery];
}

- (void)maclovin_updateMacros:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    NSString *foodNameValue = [RCTAppleHealthKit stringFromOptions:input key:@"foodName" withDefault:nil];
    NSString *mealNameValue = [RCTAppleHealthKit stringFromOptions:input key:@"mealType" withDefault:nil];
    NSDate *timeFoodWasConsumed = [RCTAppleHealthKit dateFromOptions:input key:@"finalDate" withDefault:[NSDate date]];
    HKCorrelationType *foodType = [HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierFood];
    __block BOOL sourceFound = false;
    double biotinValue = [RCTAppleHealthKit doubleFromOptions:input key:@"biotin" withDefault:(double)0];
    double caffeineValue = [RCTAppleHealthKit doubleFromOptions:input key:@"caffeine" withDefault:(double)0];
    double calciumValue = [RCTAppleHealthKit doubleFromOptions:input key:@"calcium" withDefault:(double)0];
    double carbohydratesValue = [RCTAppleHealthKit doubleFromOptions:input key:@"carbohydrates" withDefault:(double)0];
    double chlorideValue = [RCTAppleHealthKit doubleFromOptions:input key:@"chloride" withDefault:(double)0];
    double cholesterolValue = [RCTAppleHealthKit doubleFromOptions:input key:@"cholesterol" withDefault:(double)0];
    double copperValue = [RCTAppleHealthKit doubleFromOptions:input key:@"copper" withDefault:(double)0];
    double energyConsumedValue = [RCTAppleHealthKit doubleFromOptions:input key:@"energy" withDefault:(double)0];
    double fatMonounsaturatedValue = [RCTAppleHealthKit doubleFromOptions:input key:@"fatMonounsaturated" withDefault:(double)0];
    double fatPolyunsaturatedValue = [RCTAppleHealthKit doubleFromOptions:input key:@"fatPolyunsaturated" withDefault:(double)0];
    double fatSaturatedValue = [RCTAppleHealthKit doubleFromOptions:input key:@"fatSaturated" withDefault:(double)0];
    double fatTotalValue = [RCTAppleHealthKit doubleFromOptions:input key:@"fatTotal" withDefault:(double)0];
    double fiberValue = [RCTAppleHealthKit doubleFromOptions:input key:@"fiber" withDefault:(double)0];
    double folateValue = [RCTAppleHealthKit doubleFromOptions:input key:@"folate" withDefault:(double)0];
    double iodineValue = [RCTAppleHealthKit doubleFromOptions:input key:@"iodine" withDefault:(double)0];
    double ironValue = [RCTAppleHealthKit doubleFromOptions:input key:@"iron" withDefault:(double)0];
    double magnesiumValue = [RCTAppleHealthKit doubleFromOptions:input key:@"magnesium" withDefault:(double)0];
    double manganeseValue = [RCTAppleHealthKit doubleFromOptions:input key:@"manganese" withDefault:(double)0];
    double molybdenumValue = [RCTAppleHealthKit doubleFromOptions:input key:@"molybdenum" withDefault:(double)0];
    double niacinValue = [RCTAppleHealthKit doubleFromOptions:input key:@"niacin" withDefault:(double)0];
    double pantothenicAcidValue = [RCTAppleHealthKit doubleFromOptions:input key:@"pantothenicAcid" withDefault:(double)0];
    double phosphorusValue = [RCTAppleHealthKit doubleFromOptions:input key:@"phosphorus" withDefault:(double)0];
    double potassiumValue = [RCTAppleHealthKit doubleFromOptions:input key:@"potassium" withDefault:(double)0];
    double proteinValue = [RCTAppleHealthKit doubleFromOptions:input key:@"protein" withDefault:(double)0];
    double riboflavinValue = [RCTAppleHealthKit doubleFromOptions:input key:@"riboflavin" withDefault:(double)0];
    double seleniumValue = [RCTAppleHealthKit doubleFromOptions:input key:@"selenium" withDefault:(double)0];
    double sodiumValue = [RCTAppleHealthKit doubleFromOptions:input key:@"sodium" withDefault:(double)0];
    double sugarValue = [RCTAppleHealthKit doubleFromOptions:input key:@"sugar" withDefault:(double)0];
    double thiaminValue = [RCTAppleHealthKit doubleFromOptions:input key:@"thiamin" withDefault:(double)0];
    double vitaminAValue = [RCTAppleHealthKit doubleFromOptions:input key:@"vitaminA" withDefault:(double)0];
    double vitaminB12Value = [RCTAppleHealthKit doubleFromOptions:input key:@"vitaminB12" withDefault:(double)0];
    double vitaminB6Value = [RCTAppleHealthKit doubleFromOptions:input key:@"vitaminB6" withDefault:(double)0];
    double vitaminCValue = [RCTAppleHealthKit doubleFromOptions:input key:@"vitaminC" withDefault:(double)0];
    double vitaminDValue = [RCTAppleHealthKit doubleFromOptions:input key:@"vitaminD" withDefault:(double)0];
    double vitaminEValue = [RCTAppleHealthKit doubleFromOptions:input key:@"vitaminE" withDefault:(double)0];
    double vitaminKValue = [RCTAppleHealthKit doubleFromOptions:input key:@"vitaminK" withDefault:(double)0];
    double zincValue = [RCTAppleHealthKit doubleFromOptions:input key:@"zinc" withDefault:(double)0];
    
    // Metadata including some new food-related keys //
    NSDictionary *metadata = @{
                               HKMetadataKeyFoodType:foodNameValue,
                               //@"HKFoodBrandName":@"FoodBrandName", // Restaurant name or packaged food brand name
                               //@"HKFoodTypeUUID":@"FoodTypeUUID", // Identifier for this food
                               @"HKFoodMeal":mealNameValue//, // Breakfast, Lunch, Dinner, or Snacks
                               //@"HKFoodImageName":@"FoodImageName" // Food icon name
                               };
    
    // Create nutrtional data for food //
    NSMutableSet *mySet = [[NSMutableSet alloc] init];
    if (biotinValue > 0){
        HKQuantitySample* biotin = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryBiotin]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:biotinValue]
                                                                  startDate:timeFoodWasConsumed
                                                                    endDate:timeFoodWasConsumed
                                                                   metadata:metadata];
        [mySet addObject:biotin];
    }
    if (caffeineValue > 0){
        HKQuantitySample* caffeine = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCaffeine]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:caffeineValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        
        [mySet addObject:caffeine];
    }
    if (calciumValue > 0){
        HKQuantitySample* calcium = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCalcium]
                                                                    quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:calciumValue]
                                                                   startDate:timeFoodWasConsumed
                                                                     endDate:timeFoodWasConsumed
                                                                    metadata:metadata];
        [mySet addObject:calcium];
    }
    if (carbohydratesValue > 0 && [self.healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCarbohydrates]] == HKAuthorizationStatusSharingAuthorized){
        HKQuantitySample* carbohydrates = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCarbohydrates]
                                                                          quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:carbohydratesValue]
                                                                         startDate:timeFoodWasConsumed
                                                                           endDate:timeFoodWasConsumed
                                                                          metadata:metadata];
        [mySet addObject:carbohydrates];
    }
    if (chlorideValue > 0){
        HKQuantitySample* chloride = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryChloride]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:chlorideValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        [mySet addObject:chloride];
    }
    if (cholesterolValue > 0){
        HKQuantitySample* cholesterol = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCholesterol]
                                                                        quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:cholesterolValue]
                                                                       startDate:timeFoodWasConsumed
                                                                         endDate:timeFoodWasConsumed
                                                                        metadata:metadata];
        [mySet addObject:cholesterol];
    }
    if (copperValue > 0){
        HKQuantitySample* copper = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCopper]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:copperValue]
                                                                  startDate:timeFoodWasConsumed
                                                                    endDate:timeFoodWasConsumed
                                                                   metadata:metadata];
        [mySet addObject:copper];
    }
    if (energyConsumedValue > 0 && [self.healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed]] == HKAuthorizationStatusSharingAuthorized){
        HKQuantitySample* energyConsumed = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed]
                                                                           quantity:[HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:energyConsumedValue]
                                                                          startDate:timeFoodWasConsumed
                                                                            endDate:timeFoodWasConsumed
                                                                           metadata:metadata];
        [mySet addObject:energyConsumed];
    }
    if (fatMonounsaturatedValue > 0){
        HKQuantitySample* fatMonounsaturated = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatMonounsaturated]
                                                                               quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:fatMonounsaturatedValue]
                                                                              startDate:timeFoodWasConsumed
                                                                                endDate:timeFoodWasConsumed
                                                                               metadata:metadata];
        [mySet addObject:fatMonounsaturated];
    }
    if (fatPolyunsaturatedValue > 0){
        HKQuantitySample* fatPolyunsaturated = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatPolyunsaturated]
                                                                               quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:fatPolyunsaturatedValue]
                                                                              startDate:timeFoodWasConsumed
                                                                                endDate:timeFoodWasConsumed
                                                                               metadata:metadata];
        [mySet addObject:fatPolyunsaturated];
    }
    if (fatSaturatedValue > 0){
        HKQuantitySample* fatSaturated = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatSaturated]
                                                                         quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:fatSaturatedValue]
                                                                        startDate:timeFoodWasConsumed
                                                                          endDate:timeFoodWasConsumed
                                                                         metadata:metadata];
        [mySet addObject:fatSaturated];
    }
    if (fatTotalValue > 0 && [self.healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatTotal]] == HKAuthorizationStatusSharingAuthorized){
        HKQuantitySample* fatTotal = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatTotal]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:fatTotalValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        [mySet addObject:fatTotal];
    }
    if (fiberValue > 0 && [self.healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFiber]] == HKAuthorizationStatusSharingAuthorized){
        HKQuantitySample* fiber = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFiber]
                                                                  quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:fiberValue]
                                                                 startDate:timeFoodWasConsumed
                                                                   endDate:timeFoodWasConsumed
                                                                  metadata:metadata];
        [mySet addObject:fiber];
    }
    if (folateValue > 0){
        HKQuantitySample* folate = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFolate]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:folateValue]
                                                                  startDate:timeFoodWasConsumed
                                                                    endDate:timeFoodWasConsumed
                                                                   metadata:metadata];
        [mySet addObject:folate];
    }
    if (iodineValue > 0){
        HKQuantitySample* iodine = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryIodine]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:iodineValue]
                                                                  startDate:timeFoodWasConsumed
                                                                    endDate:timeFoodWasConsumed
                                                                   metadata:metadata];
        [mySet addObject:iodine];
    }
    if (ironValue > 0){
        HKQuantitySample* iron = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryIron]
                                                                 quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:ironValue]
                                                                startDate:timeFoodWasConsumed
                                                                  endDate:timeFoodWasConsumed
                                                                 metadata:metadata];
        [mySet addObject:iron];
    }
    if (magnesiumValue > 0){
        HKQuantitySample* magnesium = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryMagnesium]
                                                                      quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:magnesiumValue]
                                                                     startDate:timeFoodWasConsumed
                                                                       endDate:timeFoodWasConsumed
                                                                      metadata:metadata];
        [mySet addObject:magnesium];
    }
    if (manganeseValue > 0){
        HKQuantitySample* manganese = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryManganese]
                                                                      quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:manganeseValue]
                                                                     startDate:timeFoodWasConsumed
                                                                       endDate:timeFoodWasConsumed
                                                                      metadata:metadata];
        [mySet addObject:manganese];
    }
    if (molybdenumValue > 0){
        HKQuantitySample* molybdenum = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryMolybdenum]
                                                                       quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:molybdenumValue]
                                                                      startDate:timeFoodWasConsumed
                                                                        endDate:timeFoodWasConsumed
                                                                       metadata:metadata];
        [mySet addObject:molybdenum];
    }
    if (niacinValue > 0){
        HKQuantitySample* niacin = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryNiacin]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:niacinValue]
                                                                  startDate:timeFoodWasConsumed
                                                                    endDate:timeFoodWasConsumed
                                                                   metadata:metadata];
        [mySet addObject:niacin];
    }
    if (pantothenicAcidValue > 0){
        HKQuantitySample* pantothenicAcid = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPantothenicAcid]
                                                                            quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:pantothenicAcidValue]
                                                                           startDate:timeFoodWasConsumed
                                                                             endDate:timeFoodWasConsumed
                                                                            metadata:metadata];
        [mySet addObject:pantothenicAcid];
    }
    if (phosphorusValue > 0){
        HKQuantitySample* phosphorus = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPhosphorus]
                                                                       quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:phosphorusValue]
                                                                      startDate:timeFoodWasConsumed
                                                                        endDate:timeFoodWasConsumed
                                                                       metadata:metadata];
        [mySet addObject:phosphorus];
    }
    if (potassiumValue > 0){
        HKQuantitySample* potassium = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPotassium]
                                                                      quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:potassiumValue]
                                                                     startDate:timeFoodWasConsumed
                                                                       endDate:timeFoodWasConsumed
                                                                      metadata:metadata];
        [mySet addObject:potassium];
    }
    if (proteinValue > 0 && [self.healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryProtein]] == HKAuthorizationStatusSharingAuthorized){
        HKQuantitySample* protein = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryProtein]
                                                                    quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:proteinValue]
                                                                   startDate:timeFoodWasConsumed
                                                                     endDate:timeFoodWasConsumed
                                                                    metadata:metadata];
        [mySet addObject:protein];
    }
    if (riboflavinValue > 0){
        HKQuantitySample* riboflavin = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryRiboflavin]
                                                                       quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:riboflavinValue]
                                                                      startDate:timeFoodWasConsumed
                                                                        endDate:timeFoodWasConsumed
                                                                       metadata:metadata];
        [mySet addObject:riboflavin];
    }
    if (seleniumValue > 0){
        HKQuantitySample* selenium = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySelenium]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:seleniumValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        [mySet addObject:selenium];
    }
    if (sodiumValue > 0){
        HKQuantitySample* sodium = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySodium]
                                                                   quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:sodiumValue]
                                                                  startDate:timeFoodWasConsumed
                                                                    endDate:timeFoodWasConsumed
                                                                   metadata:metadata];
        [mySet addObject:sodium];
    }
    if (sugarValue > 0){
        HKQuantitySample* sugar = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySugar]
                                                                  quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:sugarValue]
                                                                 startDate:timeFoodWasConsumed
                                                                   endDate:timeFoodWasConsumed
                                                                  metadata:metadata];
        [mySet addObject:sugar];
    }
    if (thiaminValue > 0){
        HKQuantitySample* thiamin = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryThiamin]
                                                                    quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:thiaminValue]
                                                                   startDate:timeFoodWasConsumed
                                                                     endDate:timeFoodWasConsumed
                                                                    metadata:metadata];
        [mySet addObject:thiamin];
    }
    if (vitaminAValue > 0){
        HKQuantitySample* vitaminA = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminA]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:vitaminAValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        [mySet addObject:vitaminA];
    }
    if (vitaminB12Value > 0){
        HKQuantitySample* vitaminB12 = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminB12]
                                                                       quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:vitaminB12Value]
                                                                      startDate:timeFoodWasConsumed
                                                                        endDate:timeFoodWasConsumed
                                                                       metadata:metadata];
        [mySet addObject:vitaminB12];
    }
    if (vitaminB6Value > 0){
        HKQuantitySample* vitaminB6 = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminB6]
                                                                      quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:vitaminB6Value]
                                                                     startDate:timeFoodWasConsumed
                                                                       endDate:timeFoodWasConsumed
                                                                      metadata:metadata];
        [mySet addObject:vitaminB6];
    }
    if (vitaminCValue > 0){
        HKQuantitySample* vitaminC = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminC]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:vitaminCValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        [mySet addObject:vitaminC];
    }
    if (vitaminDValue > 0){
        HKQuantitySample* vitaminD = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminD]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:vitaminDValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        [mySet addObject:vitaminD];
    }
    if (vitaminEValue > 0){
        HKQuantitySample* vitaminE = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminE]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:vitaminEValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        
        [mySet addObject:vitaminE];
    }
    if (vitaminKValue > 0){
        HKQuantitySample* vitaminK = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminK]
                                                                     quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:vitaminKValue]
                                                                    startDate:timeFoodWasConsumed
                                                                      endDate:timeFoodWasConsumed
                                                                     metadata:metadata];
        [mySet addObject:vitaminK];
    }
    if (zincValue > 0){
        HKQuantitySample* zinc = [HKQuantitySample quantitySampleWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryZinc]
                                                                 quantity:[HKQuantity quantityWithUnit:[HKUnit gramUnit] doubleValue:zincValue]
                                                                startDate:timeFoodWasConsumed
                                                                  endDate:timeFoodWasConsumed
                                                                 metadata:metadata];
        [mySet addObject:zinc];
    }
    
    //Check if empty array (user de-authed healthkit). If so return out of method)
    if (!mySet || !mySet.count){
        callback(@[RCTMakeError(@"AHK Deauthorized all", nil, nil)]);
        return;
    }
    
    // Combine nutritional data into a food correlation //
    HKCorrelation* food = [HKCorrelation correlationWithType:foodType
                                                   startDate:timeFoodWasConsumed
                                                     endDate:timeFoodWasConsumed
                                                     objects:mySet
                                                    metadata:metadata];
    
    //declare array for source holder
    NSMutableArray *dataSources = [[NSMutableArray alloc] init];
    
    //run first query to get our app source
    HKSourceQuery *sourceMacroQuery = [[HKSourceQuery alloc] initWithSampleType:foodType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error){
        
        for (HKSource *source in sources)
        {
            if ([source.bundleIdentifier isEqualToString:@"com.prestigeworldwide.maclovin"])
            {
                sourceFound = true;
                [dataSources addObject:source];
                NSPredicate *datePredicate = [RCTAppleHealthKit predicateForSamplesBetweenDates:startDate endDate:endDate];
                NSPredicate *sourcesPredicate = [HKQuery predicateForObjectsFromSources:[NSSet setWithArray:dataSources]];
                NSArray *subPredicates = [[NSArray alloc] initWithObjects:sourcesPredicate, datePredicate, nil];
                NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
                //run second query to get querey dates weight
                HKSampleQuery *updateMacroQuery = [[HKSampleQuery alloc] initWithSampleType:foodType predicate:compoundPredicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (HKCorrelation *foodCorrelation in results) {
                            if([[foodCorrelation.metadata valueForKey:HKMetadataKeyFoodType] isEqualToString:@"MyKeto"]) {
                                NSSet *objs = foodCorrelation.objects;
                                for (HKQuantitySample *sample in objs) {
                                    [self.healthStore deleteObject:sample withCompletion:^(BOOL success, NSError *error) {
                                        if (success) {
                                            NSLog(@"Success. delete sample");
                                        }
                                        else {
                                            NSLog(@"delete: An error occured deleting the sample. In your app, try to handle this gracefully. The error was: %@.", error);
                                        }
                                    }];
                                }
                                
                                [self.healthStore deleteObject:foodCorrelation withCompletion:^(BOOL success, NSError *error) {
                                    if (success) {
                                        NSLog(@"Success. delete %@", [foodCorrelation.metadata valueForKey:HKMetadataKeyExternalUUID]);
                                    }
                                    else {
                                        NSLog(@"delete: An error occured deleting the Correlation. In your app, try to handle this gracefully. The error was: %@.", error);
                                    }
                                }];
                                return;
                            }
                        }
                    });
                    
                    // Save the food correlation to HealthKit after deleting previous entry if there was one //
                    [self.healthStore saveObject:food withCompletion:^(BOOL success, NSError *error) {
                        if (!success) {
                            callback(@[RCTMakeError(@"error saving the food sample with sources", error, nil)]);
                        }else{
                            callback(@[[NSNull null], @(energyConsumedValue)]);
                        }
                    }];
                    return;
                    
                }];
                [self.healthStore executeQuery:updateMacroQuery];
            }
        }
        
        // Save the food correlation to HealthKit if no sources were found ie user never saved healthkit data before for food //
        if([sources count] == 0 || sourceFound == false){
            [self.healthStore saveObject:food withCompletion:^(BOOL success, NSError *error) {
                if (!success) {
                    callback(@[RCTMakeError(@"error saving the food sample with no sources at all", error, nil)]);
                }else{
                    callback(@[[NSNull null], @(energyConsumedValue)]);
                }
                
            }];
        }
        
    }];
    [self.healthStore executeQuery:sourceMacroQuery];
    
}

- (void)maclovin_clearMacros:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback
{
    NSDate *startDate = [RCTAppleHealthKit dateFromOptions:input key:@"startDate" withDefault:nil];
    NSDate *endDate = [RCTAppleHealthKit dateFromOptions:input key:@"endDate" withDefault:[NSDate date]];
    HKCorrelationType *foodType = [HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierFood];
    
    //declare array for source holder
    NSMutableArray *dataSources = [[NSMutableArray alloc] init];
    
    //run first query to get our app source
    HKSourceQuery *sourceClearMacroQuery = [[HKSourceQuery alloc] initWithSampleType:foodType samplePredicate:nil completionHandler:^(HKSourceQuery *query, NSSet *sources, NSError *error){
        
        for (HKSource *source in sources)
        {
            if ([source.bundleIdentifier isEqualToString:@"com.prestigeworldwide.maclovin"])
            {
                [dataSources addObject:source];
                NSPredicate *datePredicate = [RCTAppleHealthKit predicateForSamplesBetweenDates:startDate endDate:endDate];
                NSPredicate *sourcesPredicate = [HKQuery predicateForObjectsFromSources:[NSSet setWithArray:dataSources]];
                NSArray *subPredicates = [[NSArray alloc] initWithObjects:sourcesPredicate, datePredicate, nil];
                NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
                //run second query to get querey dates weight
                HKSampleQuery *clearCorrelationQuery = [[HKSampleQuery alloc] initWithSampleType:foodType predicate:compoundPredicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (HKCorrelation *foodCorrelation in results) {
                            if([[foodCorrelation.metadata valueForKey:HKMetadataKeyFoodType] isEqualToString:@"MyKeto"]) {
                                NSSet *objs = foodCorrelation.objects;
                                for (HKQuantitySample *sample in objs) {
                                    [self.healthStore deleteObject:sample withCompletion:^(BOOL success, NSError *error) {
                                        if (success) {
                                            NSLog(@"Success. delete sample");
                                        }
                                        else {
                                            NSLog(@"delete: An error occured deleting the sample. In your app, try to handle this gracefully. The error was: %@.", error);
                                        }
                                    }];
                                }
                                
                                [self.healthStore deleteObject:foodCorrelation withCompletion:^(BOOL success, NSError *error) {
                                    if (!success) {
                                        callback(@[RCTMakeError(@"error saving the food sample with no sources at all", error, nil)]);
                                    }else{
                                        callback(@[[NSNull null], @"Deleted"]);
                                    }
                                }];
                                return;
                            }
                        }
                    });
                }];
                [self.healthStore executeQuery:clearCorrelationQuery];
            }
        }
    }];
    [self.healthStore executeQuery:sourceClearMacroQuery];
}

@end
