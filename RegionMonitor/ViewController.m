//
//  ViewController.m
//  RegionMonitor
//
//  Created by Steven Jo on 13/01/2015.
//  Copyright (c) 2015 Dev1. All rights reserved.
//

#import "ViewController.h"
#import "LocationDelegate.h"
#import "AppDelegate.h"
#import <MapKit/MapKit.h>

@interface ViewController ()<MKMapViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) MKMapView *mapView;
@property (nonatomic,weak) LocationDelegate *locationController;
@property (nonatomic,weak) AppDelegate *appDelegate;
@property (weak) MKPointAnnotation *lastAnnotation;
@property (weak) MKCircle *circle;
@property (nonatomic) UIAlertView *alert;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _appDelegate = [UIApplication sharedApplication].delegate;
    _locationController = _appDelegate.locationController;
    _mapView = [[MKMapView alloc] initWithFrame:self.view.frame];
    _mapView.delegate = self;
    _mapView.mapType = MKMapTypeStandard;
    [self.view addSubview:_mapView];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    navBar.translucent = NO;
    [self.view addSubview:navBar];
    UIBarButtonItem *locIcon = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(location)];
    UIBarButtonItem *addIcon = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(dropPin)];
    
    UIBarButtonItem *deleteIcon = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAll)];
    UIBarButtonItem *refreshIcon = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshPoint)];

    UINavigationItem *navigItem = [[UINavigationItem alloc] initWithTitle:@"Region Monitoring"];
    navigItem.rightBarButtonItems = @[refreshIcon,deleteIcon];
    navigItem.leftBarButtonItems = @[addIcon,locIcon];
    navBar.items = [NSArray arrayWithObjects: navigItem,nil];
    
    [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5; //user needs to press for half a second.
    [_mapView addGestureRecognizer:lpgr];

}
-(void)viewWillAppear:(BOOL)animated{
    [self refreshPoint];
}
-(void)refreshPoint{
    [_mapView removeOverlays:_mapView.overlays];
    [_mapView removeAnnotations:_mapView.annotations];
    for (CLCircularRegion *region in [_locationController.locationManager.monitoredRegions allObjects]) {
        MKPointAnnotation* point = [[MKPointAnnotation alloc] init];
        point.coordinate = region.center;
        point.title = region.identifier;
        [_mapView addAnnotation:point];
        MKCircle *cir = [MKCircle circleWithCenterCoordinate:point.coordinate radius:ITGMapRegionRadius];
        [_mapView addOverlay:cir];
    }
}
-(void)deleteAll{
    [_mapView removeOverlays:_mapView.overlays];
    [_mapView removeAnnotations:_mapView.annotations];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    for (CLCircularRegion *region in [_locationController.locationManager.monitoredRegions allObjects]) {
        [_locationController.locationManager stopMonitoringForRegion:region];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)location{
    
    if ([_mapView userTrackingMode] == MKUserTrackingModeNone) {
        [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    }
    else
    {
        [_mapView setUserTrackingMode:MKUserTrackingModeNone];
    }
//    for (CLCircularRegion *region in [_locationController.locationManager.monitoredRegions allObjects]) {
//        NSArray *myArray = [[NSUserDefaults standardUserDefaults] objectForKey:region.identifier];
//        NSLog(@"identifier  : %@ \n%@",region.identifier,myArray);
//
//        for (NSString *value in myArray) {
//            NSLog(@"\n%@",value);
//        }
//    }
    NSLog(@"sjs\n%@",[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSLog(@"cur %@ %f",_locationController.locationManager.location, _locationController.locationManager.location.horizontalAccuracy);
    NSLog(@"localnotification %@",[UIApplication sharedApplication].scheduledLocalNotifications);

}

-(void)dropPin{
    [self dropPinAtCoordinate:_mapView.userLocation.coordinate];
}

-(void)dropPinAtCoordinate:(CLLocationCoordinate2D)coordinate{
    [_mapView setCenterCoordinate:coordinate animated:YES];
    
    MKPointAnnotation* point = [[MKPointAnnotation alloc] init];
    point.coordinate = coordinate;
    [_mapView addAnnotation:point];
    self.lastAnnotation = point;
    self.lastAnnotation.title = [NSString stringWithFormat:@"%f, %f",coordinate.latitude,coordinate.longitude];
    
    MKCircle *cir = [MKCircle circleWithCenterCoordinate:coordinate radius:ITGMapRegionRadius];
    [_mapView addOverlay:cir];
    
    self.circle = cir;
    
    self.alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add a Workplace?", @"Maps2go")
                                            message:[NSString stringWithFormat:@"(%f, %f)",point.coordinate.latitude, point.coordinate.longitude]
                                           delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [self.alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [self.alert show];

}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if([alertView.title isEqualToString:NSLocalizedString(@"Add a Workplace?", @"Maps2go")]){
        NSString *name = [alertView textFieldAtIndex:0].text.length > 0 ? [alertView textFieldAtIndex:0].text : @"";
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Yes", @"")] && name.length > 0){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary *dict = @{ITGMapNotificationLatitude:@(self.lastAnnotation.coordinate.latitude),
                                           ITGMapNotificationLongitude:@(self.lastAnnotation.coordinate.longitude),
                                           ITGMapNotificationName:name};
                    self.lastAnnotation.title = name;
                    [_locationController registerLocalNotificationWithDictionary:dict];
                    NSLog(@"dict %@",dict);
                });
            });
            
        }else{
            [_mapView removeAnnotation:self.lastAnnotation];
            [_mapView removeOverlay:self.circle];
        }
    }

}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];
    CLLocationCoordinate2D touchMapCoordinate = [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
    [self dropPinAtCoordinate:touchMapCoordinate];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
    if(pinView == nil) {
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"];
        [pinView setPinColor:MKPinAnnotationColorPurple];
        
        pinView.animatesDrop = YES;
        pinView.canShowCallout = YES;
    } else {
        pinView.annotation = annotation;
    }
    
    return pinView;
}
-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay{
    MKCircleView* circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    circleView.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:.3];
    return circleView;
}

@end
