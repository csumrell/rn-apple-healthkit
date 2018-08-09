//
//  RCTAppleHealthKit+Methods_MacLovin.h
//  RCTAppleHealthKit
//
//  
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "RCTAppleHealthKit.h"

@interface RCTAppleHealthKit (Methods_MacLovin)

- (void)maclovin_updateWeight:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)maclovin_updateWater:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)maclovin_updateMacros:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;
- (void)maclovin_clearMacros:(NSDictionary *)input callback:(RCTResponseSenderBlock)callback;

@end
