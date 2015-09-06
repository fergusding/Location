//
//  ViewController.m
//  Location
//
//  Created by fergusding on 15/9/2.
//  Copyright (c) 2015年 fergusding. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *locationTextfield;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) CLLocationManager *manager;
@property (strong, nonatomic) CLGeocoder *geocoder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareForLocation];
    [self prepareForGeocode];
    [self prepareForMapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Private

- (void)prepareForLocation {
    [_manager = [CLLocationManager alloc] init];
    _manager.delegate = self;
    
    if ([CLLocationManager locationServicesEnabled]) {
        if ([_manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_manager requestWhenInUseAuthorization];
        } else {
            [_manager startUpdatingLocation];
        }
    }
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            [_manager requestWhenInUseAuthorization];
            break;
            
        case kCLAuthorizationStatusAuthorizedAlways:
            
        case kCLAuthorizationStatusDenied:
            
        case kCLAuthorizationStatusRestricted: {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请求使用定位失败" message:@"需要使用定位，请设置为‘InUse’" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }]];
                
                [self presentViewController:alert animated:YES completion:nil];
            });
            break;
        }
            
        default:
            break;
    }
}

- (void)prepareForGeocode {
    _geocoder = [[CLGeocoder alloc] init];
    
    // 同时只能执行下面两个函数其中一个？？？？？？？？  YES, 可以放在回调里面执行另外一个
    [_geocoder geocodeAddressString:@"上海" completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks firstObject];
        NSLog(@"%@, %@", placemark.location, placemark.region);
    }];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:22.284681 longitude:114.158177];
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks firstObject];
        NSLog(@"%@", placemark.addressDictionary);
    }];
}

- (void)prepareForMapView {
    // 用户位置追踪(用户位置追踪用于标记用户当前位置，此时会调用定位服务)
    _mapView.userTrackingMode = MKUserTrackingModeFollow;
    _mapView.mapType = MKMapTypeStandard;
    _mapView.delegate = self;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [_manager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = locations[0];
    NSLog(@"%f", location.coordinate.latitude);
    
    [_manager stopUpdatingLocation];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation"];
    }
    annotationView.pinColor = MKPinAnnotationColorRed;
    annotationView.animatesDrop = YES;
    annotationView.canShowCallout = YES;
    return annotationView;
}

#pragma mark - IBActions

- (IBAction)openMap:(id)sender {
    [_geocoder geocodeAddressString:self.locationTextfield.text completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks firstObject];
        CLLocation *location = placemark.location;
        CLLocationCoordinate2D position = location.coordinate;
        
        MKCoordinateRegion region = MKCoordinateRegionMake(position, MKCoordinateSpanMake(0.05, 0.05));
        region = [_mapView regionThatFits:region];
        _mapView.region = region;
        
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.title = placemark.locality;
        annotation.subtitle = placemark.name;
        annotation.coordinate = position;
        [_mapView addAnnotation:annotation];
    }];
}

@end
