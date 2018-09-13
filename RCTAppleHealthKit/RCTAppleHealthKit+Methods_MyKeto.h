//
//  RCTAppleHealthKit+Methods_MyKeto.h
//  RCTAppleHealthKit
//
//  
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit.h"

@interface RCTAppleHealthKit (Methods_MyKeto)

- (void)prestige_updateWeight:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)prestige_updateWater:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)prestige_saveGlucose:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)prestige_deleteGlucose:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)prestige_updateMacros:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)prestige_clearMacros:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;

@end
