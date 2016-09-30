//
//  SMSAdvertisedViewController.h
//  SMS Scheduler
//
//Created by ilabafrica on 24/08/2016.
// Copyright © 2016 Strathmore. All rights reserved.

#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface SMSAdvertisedViewController : UIViewController<GADBannerViewDelegate>

@property (nonatomic, weak) IBOutlet GADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet GADBannerView *noDataBannerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraint;

@end
