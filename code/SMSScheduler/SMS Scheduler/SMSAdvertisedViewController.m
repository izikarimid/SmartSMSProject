//
//  SMSAdvertisedViewController.m
//  SMS Scheduler
//
//Created by ilabafrica on 24/08/2016.
// Copyright © 2016 Strathmore. All rights reserved.

//

#import "SMSAdvertisedViewController.h"
#import "SMSConstants.h"

@interface SMSAdvertisedViewController ()

@property (nonatomic) CGFloat initialLyaoutConstraintConstant;

@end

@implementation SMSAdvertisedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SMSAdMobUnitID.length) {
        [self configureAds];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (SMSAdMobUnitID.length) {
        [self loadAds];
    }
}

- (void)configureAds
{
    self.initialLyaoutConstraintConstant = self.layoutConstraint.constant;
    self.bannerView.alpha = self.noDataBannerView.alpha = 0.0;
    self.bannerView.adUnitID = SMSAdMobUnitID;
    self.noDataBannerView.adUnitID = SMSAdMobUnitID;
    self.bannerView.delegate = self;
    self.noDataBannerView.delegate = self;
    
    self.noDataBannerView.layer.zPosition = 200.0;
}

- (void)loadAds
{
    self.noDataBannerView.rootViewController = self.bannerView.rootViewController = self.view.window.rootViewController;
    GADRequest *request = [GADRequest request];
    request.testDevices = @[ kGADSimulatorID ];
    
    self.bannerView.autoloadEnabled = self.noDataBannerView.autoloadEnabled = YES;
}

- (void)animateLayoutConstraintChange:(CGFloat)constant
{
    self.layoutConstraint.constant = constant;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
        self.bannerView.alpha = constant > 0 ? 1.0 : 0.0;
    } completion:nil];
}

#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    if (bannerView == self.bannerView) {
        [self animateLayoutConstraintChange:CGRectGetHeight(self.bannerView.frame) + self.initialLyaoutConstraintConstant];
    } else if (bannerView == self.noDataBannerView) {
        [UIView animateWithDuration:0.3 animations:^{
            self.noDataBannerView.alpha = 1.0;
        } completion:nil];
    }
}

- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error
{
    if (bannerView == self.bannerView) {
        [self animateLayoutConstraintChange:self.initialLyaoutConstraintConstant];
    } else if (bannerView == self.noDataBannerView) {
        [UIView animateWithDuration:0.3 animations:^{
            self.noDataBannerView.alpha = 0.0;
        } completion:nil];
    }
}

@end
