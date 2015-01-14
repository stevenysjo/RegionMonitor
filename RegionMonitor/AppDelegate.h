//
//  AppDelegate.h
//  RegionMonitor
//
//  Created by Steven Jo on 13/01/2015.
//  Copyright (c) 2015 Dev1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationDelegate.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) LocationDelegate *locationController;


@end

