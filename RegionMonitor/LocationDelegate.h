//
//  LocationDelegate.h
//  RegionMonitor
//
//  Created by Steven Jo on 13/01/2015.
//  Copyright (c) 2015 Dev1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSInteger const ITGMapRegionRadius;
extern NSString * const ITGMapNotificationName;
extern NSString * const ITGMapNotificationLatitude;
extern NSString * const ITGMapNotificationLongitude;
extern NSString * const ITGMapNotificationID;

@interface LocationDelegate : NSObject <CLLocationManagerDelegate>
@property (nonatomic) CLLocationManager *locationManager;

-(void)registerLocalNotificationWithDictionary:(NSDictionary *)dict;

@end
