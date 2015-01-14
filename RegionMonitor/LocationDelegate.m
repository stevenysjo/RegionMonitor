//
//  LocationDelegate.m
//  RegionMonitor
//
//  Created by Steven Jo on 13/01/2015.
//  Copyright (c) 2015 Dev1. All rights reserved.
//

#import "LocationDelegate.h"
#import <Foundation/Foundation.h>
#import "AppDelegate.h"
NSInteger const ITGMapRegionRadius = 100;
NSString * const ITGMapNotificationLatitude = @"latitude";
NSString * const ITGMapNotificationLongitude = @"longitude";
NSString * const ITGMapNotificationName = @"name";
NSString * const ITGMapNotificationID = @"identifier";


@implementation LocationDelegate
-(instancetype)init{
    self = [super init];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways &&
       [_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
        [_locationManager performSelector:@selector(requestAlwaysAuthorization)];
    }
    
    return self;
}
-(void)registerLocalNotificationWithDictionary:(NSDictionary *)dict{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([dict[ITGMapNotificationLatitude] doubleValue],
                                                                    [dict[ITGMapNotificationLongitude] doubleValue]);
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:coordinate radius:ITGMapRegionRadius identifier:dict[ITGMapNotificationName]];
//    NSString *message = [NSString stringWithFormat:@"Notif %@",region.identifier];

//    UILocalNotification *loc = [[UILocalNotification alloc] init];
//    loc.region = region;
//    loc.regionTriggersOnce = NO;
//    loc.alertBody = message;
//    [[UIApplication sharedApplication] scheduleLocalNotification:loc];
    [_locationManager startMonitoringForRegion:region];
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    NSLog(@"%s %@",__PRETTY_FUNCTION__,manager.location.description);
}
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLCircularRegion *)region{
    CLLocation *center = [[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude];
    CLLocation *userLocation = manager.location;
    CGFloat distance = [userLocation distanceFromLocation:center];
    NSString *message = [NSString stringWithFormat:@"Enter %@ \nDistance %f\nAccuracy %f",region.identifier,distance,userLocation.horizontalAccuracy];
    [self addLogWithManager:manager region:region enter:YES];
    
    UILocalNotification *locNotification = [[UILocalNotification alloc] init];
    locNotification.alertBody = message;
    [[UIApplication sharedApplication] presentLocalNotificationNow:locNotification];

    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter region" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}
-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLCircularRegion *)region{
    CLLocation *center = [[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude];
    CLLocation *userLocation = manager.location;
    CGFloat distance = [userLocation distanceFromLocation:center];
    NSString *message = [NSString stringWithFormat:@"Exit %@ \nDistance %f\nAccuracy %f",region.identifier,distance,userLocation.horizontalAccuracy];
    
    [self addLogWithManager:manager region:region enter:NO];

    UILocalNotification *locNotification = [[UILocalNotification alloc] init];
    locNotification.alertBody = message;
    [[UIApplication sharedApplication] presentLocalNotificationNow:locNotification];
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exit region" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}
-(void)addLogWithManager:(CLLocationManager *)manager region:(CLCircularRegion *)region enter:(BOOL)enter{
    NSString *identifier = region.identifier;
    NSString *state = enter ? @"enter" : @"exit";
    NSString *message = [NSString stringWithFormat:@"%@ %@",state,region.identifier];
    CLLocation *center = [[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude];
    CLLocation *userLocation = manager.location;
    CGFloat distance = [userLocation distanceFromLocation:center];
    NSString *log = [NSString stringWithFormat:@"------------\n%@ \nRegion    : %@\nCurrent   : %@\nDistance  : %f\nAccuracy  : %f\n\n-----------",message,region,userLocation,distance,userLocation.horizontalAccuracy];
    
    NSMutableArray *logs;
    if([[NSUserDefaults standardUserDefaults] objectForKey:identifier]){
        logs = [[[NSUserDefaults standardUserDefaults] objectForKey:identifier] mutableCopy];
    }else{
        logs = [NSMutableArray array];
    }
    [logs addObject:log];
    [[NSUserDefaults standardUserDefaults] setObject:logs forKey:identifier];
    
    NSLog(@"log %@",[[NSUserDefaults standardUserDefaults] objectForKey:identifier]);

}
@end
