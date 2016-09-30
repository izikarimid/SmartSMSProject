//
//  SMSDashboardViewController.m
//  SMS Scheduler
//
//Created by ilabafrica on 24/08/2016.
// Copyright © 2016 Strathmore. All rights reserved.

#import "SMSDashboardViewController.h"
#import "SMSNewSMSViewController.h"
#import <MessageUI/MessageUI.h>
#import "SMSTableViewCell.h"
#import "SMSPopUpMenu.h"
#import "SMSConstants.h"
#import "AppDelegate.h"
#import "SMSManager.h"
#import "SMSColors.h"

@interface SMSDashboardViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *noDataView;

@property (weak, nonatomic) IBOutlet UIView *navigatorView;
@property (weak, nonatomic) IBOutlet UILabel *navigationLabel;

@property (weak, nonatomic) IBOutlet UIView *smsView;

@property (weak, nonatomic) IBOutlet UIView *addNewSMSView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addNewSMSViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addNewSMSViewHeight;

@property (strong, nonatomic) UIBarButtonItem *addSMSButton;
@property (strong, nonatomic) UIBarButtonItem *moreButton;

@property (weak, nonatomic) IBOutlet UITableView *tableVIew;

@property (strong, nonatomic) NSMutableArray *scheduled;
@property (strong, nonatomic) NSMutableArray *all;
@property (strong, nonatomic) NSMutableArray *sent;

@property (nonatomic) BOOL showScheduled;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (strong, nonatomic) SMSNewSMSViewController *SMSnewVc;

@property (strong, nonatomic) NSMutableArray *recepients;

@property (strong, nonatomic) SMS *smsToSend;

@end

@implementation SMSDashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableVIew.dataSource   = self;
    self.tableVIew.delegate     = self;
    self.tableVIew.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableVIew.bounds.size.width, 0.01f)];
    
    self.showScheduled = YES;
    
    [self addNotificationObservers];
    
    [self registerCells];
    
    [self addNavBarButtons];
    
    [self reloadAllSMSs];
    
    self.noDataView.hidden = self.all.count > 0 ? YES : NO;
    self.navigatorView.hidden = !self.noDataView.hidden;
    self.smsView.hidden =  !self.noDataView.hidden;
    
    [self.tableVIew reloadData];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.smsInfo && self.scheduled.count > 0) {
        for (SMS *sms in self.scheduled) {
            if ([sms.date isEqualToDate:appDelegate.smsInfo[@"date"]] && [sms.recepientName isEqualToString:appDelegate.smsInfo[@"recepients"]]) {
                [self sendScheduledSMS:sms];
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self setUp];

    [self setTableViewBackGround];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addNotificationObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSMSs:) name:@"reloadSMSs" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendSMS:) name:@"sendSMS" object:nil];
}

- (void)sendSMS:(NSNotification *)notification {
    
    NSDictionary *smsInfo = notification.userInfo;
    
    if (self.scheduled.count > 0) {
        for (SMS *sms in self.scheduled) {
            if ([sms.date isEqualToDate:smsInfo[@"date"]] && [sms.recepientName isEqualToString:smsInfo[@"recepients"]]) {
                [self sendScheduledSMS:sms];
            }
        }
    }
}

- (void)reloadSMSs:(NSNotification *)notification {
    
    self.navigationItem.rightBarButtonItems     = @[self.addSMSButton];
    
    [self reloadAllSMSs];
    
    self.noDataView.hidden = self.all.count > 0 ? YES : NO;
    self.navigatorView.hidden = !self.noDataView.hidden;
    self.smsView.hidden =  !self.noDataView.hidden;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.addNewSMSViewTopConstraint.constant = self.view.frame.size.height;
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL completed) {
        
        self.navigationLabel.text = NSLocalizedString(@"DashboardTitleKey", nil);
        
    }];

    [self setTableViewBackGround];
}

- (void)reloadAllSMSs {
    
    self.scheduled  = [NSMutableArray new];
    self.all        = [NSMutableArray new];
    self.sent       = [NSMutableArray new];
    
    NSManagedObjectContext *managedObjectContext    = [[SMS sharedInstance] managedObjectContext];
    NSFetchRequest *fetchRequest                    = [[NSFetchRequest alloc] initWithEntityName:@"SMS"];
    
    self.all = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    self.all = [[[self.all reverseObjectEnumerator] allObjects] mutableCopy];
    
    for (SMS *sms in self.all) {
        if (sms.sent == NO) {
            [self.scheduled addObject:sms];
        } else {
            [self.sent addObject:sms];
        }
    }
    
    [self.tableVIew reloadData];
}

- (IBAction)toggleNewSMSButton:(UIBarButtonItem *)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clear" object:nil userInfo:nil];
    
    UIBarButtonItem *cancelButton   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(toggleCancelButton:)];
    
    self.navigationItem.rightBarButtonItems = @[cancelButton];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.addNewSMSViewTopConstraint.constant = 0;
        self.addNewSMSViewHeight.constant = self.view.frame.size.height - self.navigatorView.frame.size.height;
        
        self.noDataView.hidden      = YES;
        self.navigatorView.hidden   = NO;
        self.smsView.hidden         = NO;
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL completed) {
    
        self.navigationLabel.text = NSLocalizedString(@"ContactDateMessageTitleKey", nil);
        
    }];
}

- (IBAction)toggleMoreButton:(UIBarButtonItem *)sender {
    
    UIView *targetView = (UIView *)[self.moreButton performSelector:@selector(view)];
    CGRect rect = targetView.frame;
    
    [KxMenu showMenuInView:self.view fromRect:rect menuItems:@[[KxMenuItem menuItem:NSLocalizedString(@"RateAppKey", nil) image:nil target:self action:@selector(rateApp)]]];
}

- (void)rateApp {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", APP_STORE_ID]]];
    
}

- (IBAction)toggleCancelButton:(UIBarButtonItem *)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clear" object:nil userInfo:nil];
    
    [self addNavBarButtons];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.addNewSMSViewTopConstraint.constant = self.view.frame.size.height;
        
        [self reloadAllSMSs];
        
        [self.tableVIew reloadData];
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL completed) {
        
        self.navigationLabel.text = NSLocalizedString(@"DashboardTitleKey", nil);
        
    }];
}

- (IBAction)toggleSegmentedControl:(UISegmentedControl *)sender {
    
    
    switch (sender.selectedSegmentIndex) {
        case 0:
            
            self.showScheduled = YES;
            [self setTableViewBackGround];
            
            break;
            
        case 1:
            
            self.showScheduled = NO;
            [self setTableViewBackGround];
            
            break;
            
        default:
            
            self.showScheduled = YES;
            [self setTableViewBackGround];
            
            break;
    }
    
    [self.tableVIew reloadData];
    
}

- (void)addNavBarButtons {
    
    self.addSMSButton   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(toggleNewSMSButton:)];
    self.moreButton     = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_moreItem"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleMoreButton:)];
    
    self.navigationItem.leftBarButtonItems      = @[self.moreButton];
    self.navigationItem.rightBarButtonItems     = @[self.addSMSButton];
}

- (void)registerCells {
    
    [SMSTableViewCell registerNibInTableView:self.tableVIew];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.showScheduled ? self.scheduled.count : self.sent.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SMSTableViewCell dequereCellInTableView:self.tableVIew indexPath:indexPath sms:[self.showScheduled ? self.scheduled : self.sent objectAtIndex:indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {

    }
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.showScheduled) {
        
        SMS *sentSms = [self.scheduled objectAtIndex:indexPath.row];
        
        if ([sentSms.date timeIntervalSinceNow] < 0) {
            UITableViewRowAction *button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"DeleteKey", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self cancelLocalNotificationForSMS:sentSms];
                
                [self.scheduled removeObjectAtIndex:indexPath.row];
                [self removeSMSFromCoreData:sentSms];
                [self.tableVIew reloadData];
                
                [self setTableViewBackGround];
                
            }];
            button.backgroundColor = [SMSColors alertColor];
            
            UITableViewRowAction *sendButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"SendKey", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self cancelLocalNotificationForSMS:sentSms];
                
                [self sendScheduledSMS:[self.scheduled objectAtIndex:indexPath.row]];
                
            }];
            sendButton.backgroundColor = [SMSColors defaultColor];
            
            return @[sendButton, button];
        } else {
            UITableViewRowAction *button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"CancelKey", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
                [self cancelLocalNotificationForSMS:sentSms];
                
                [self.scheduled removeObjectAtIndex:indexPath.row];
                [self removeSMSFromCoreData:sentSms];
                
                [self setTableViewBackGround];
                [self.tableVIew reloadData];
            
            }];
            button.backgroundColor = [SMSColors defaultColor];
        
            return @[button];
        }
    } else {
        
        SMS *sentSms = [self.sent objectAtIndex:indexPath.row];
        
        UITableViewRowAction *button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"DeleteKey", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self.sent removeObjectAtIndex:indexPath.row];
            [self removeSMSFromCoreData:sentSms];
            
            [self setTableViewBackGround];
            
            [self.tableVIew reloadData];
            
        }];
        button.backgroundColor = [SMSColors defaultColor];
        
        return @[button];
        
    }
}

- (void)cancelLocalNotificationForSMS:(SMS *)SMS {
    NSArray *notificationArray = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for(UILocalNotification *notification in notificationArray){
        if ([notification.alertBody isEqualToString:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"SendSMSToKey", nil), SMS.recepientName]] && [notification.userInfo[@"date"] isEqualToDate:SMS.date]) {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}

- (void)removeSMSFromCoreData:(SMS *)sms {

    NSManagedObjectContext *managedObjectContext = [[SMS sharedInstance] managedObjectContext];
    
    [managedObjectContext deleteObject:sms];

    NSError *error;
    [managedObjectContext save:&error];
}

- (void)setTableViewBackGround {
    
    UILabel *noSMSs = [[UILabel alloc] initWithFrame:self.tableVIew.frame];
    noSMSs.numberOfLines = 0;
    noSMSs.textAlignment = NSTextAlignmentCenter;
    noSMSs.lineBreakMode = NSLineBreakByWordWrapping;
    noSMSs.textColor = [SMSColors emptyState];
    [noSMSs setFont:[UIFont fontWithName: @"Helvetica-Light"size: 20.0]];
    
    if (self.showScheduled && self.scheduled.count == 0) {

        noSMSs.text = NSLocalizedString(@"NoScheduledSMSKey", nil);
        self.tableVIew.backgroundView = noSMSs;

    } else if (!self.showScheduled && self.sent.count == 0) {
        
        noSMSs.text = NSLocalizedString(@"NoSentSMSKey", nil);
        self.tableVIew.backgroundView = noSMSs;
        
    } else {
        self.tableVIew.backgroundView = nil;
    }
}

- (void)sendScheduledSMS:(SMS *)scheduledSms {
    
    self.smsToSend = scheduledSms;
    
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"SMSNotSupportedKey" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:scheduledSms.recepientNumbers];
    
    NSArray *recipents = array;
    NSString *message = [NSString stringWithFormat:@"%@", scheduledSms.text];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipents];
    [messageController setBody:message];
    
    [self presentViewController:messageController animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled: {
            
            SMS *sentSms = self.smsToSend;
            
            if (![sentSms.repeatInterval isEqualToString:NSLocalizedString(@"NeverRepeatKey", nil)]) {
                [[SMSManager sharedManager] rescheduleSMS:sentSms];
                [self removeSMSFromCoreData:sentSms];
            }
            
            NSManagedObjectContext *managedObjectContext   = [[SMS sharedInstance] managedObjectContext];
            NSError *error = nil;
            [managedObjectContext save:&error];
            
            break;
        }
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:NSLocalizedString(@"FailedToSendSMSKey", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            
            SMS *sentSms = self.smsToSend;
            
            if (![sentSms.repeatInterval isEqualToString:NSLocalizedString(@"NeverRepeatKey", nil)]) {
                [[SMSManager sharedManager] rescheduleSMS:sentSms];
            }
            
            NSManagedObjectContext *managedObjectContext   = [[SMS sharedInstance] managedObjectContext];
            NSError *error = nil;
            [managedObjectContext save:&error];
            
            break;
        }
            
        case MessageComposeResultSent: {
            
            SMS *sentSms = self.smsToSend;
            
            if (![sentSms.repeatInterval isEqualToString:NSLocalizedString(@"NeverRepeatKey", nil)]) {
                [[SMSManager sharedManager] rescheduleSMS:sentSms];
            }
            
            sentSms.sent = YES;
            
            NSManagedObjectContext *managedObjectContext   = [[SMS sharedInstance] managedObjectContext];
            NSError *error = nil;
            [managedObjectContext save:&error];
        }
            break;
            
        default:
            break;
    }
    
    [self reloadAllSMSs];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setUp {
    
    self.title = NSLocalizedString(@"SMSSchedulerKeyy", nil);
    self.tableVIew.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [SMSColors defaultColor];
    self.segmentedControl.tintColor = [SMSColors defaultColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bg_big"] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    [self.segmentedControl setTitle:NSLocalizedString(@"ScheduledKey", nil) forSegmentAtIndex:0];
    [self.segmentedControl setTitle:NSLocalizedString(@"SentKey", nil) forSegmentAtIndex:1];
}

@end
