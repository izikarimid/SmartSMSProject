//
//  SMSManager.m
//  SMS Scheduler
//
//Created by ilabafrica on 24/08/2016.
// Copyright © 2016 Strathmore. All rights reserved.

#import "SMSManager.h"

@interface SMSManager ()

@property (strong, nonatomic) NSMutableArray         *_scheduledSMSs;
@property (strong, nonatomic) NSMutableArray         *_sentSMSs;
@property (strong, nonatomic) NSMutableArray         *_allSMSs;

@end

@implementation SMSManager

+ (SMSManager *)sharedManager
{
    static SMSManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[SMSManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self._scheduledSMSs = [NSMutableArray new];
        self._sentSMSs      = [NSMutableArray new];
        self._allSMSs       = [NSMutableArray new];
    }
    return self;
}

- (NSArray *)scheduledSMSs {
    
    for (SMS *sms in self.allSMSs) {
        if (!sms.sent) {
            [self._scheduledSMSs addObject:sms];
        }
    }
    
    return self._scheduledSMSs;
}

- (NSArray *)sentSMSs {
    
    for (SMS *sms in self.allSMSs) {
        if (sms.sent) {
            [self._sentSMSs addObject:sms];
        }
    }
    
    return self._sentSMSs;
}

- (NSArray *)allSMSs {
    
    NSManagedObjectContext *managedObjectContext    = [[SMS sharedInstance] managedObjectContext];
    NSFetchRequest *fetchRequest                    = [[NSFetchRequest alloc] initWithEntityName:@"SMS"];
    
    self._allSMSs = [[managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy];
    self._allSMSs = [[[self._scheduledSMSs reverseObjectEnumerator] allObjects] mutableCopy];
    
    return self._allSMSs;
}

- (void)scheduleSMSWithRecepients:(NSArray *)recepients phones:(NSArray *)phones date:(NSDate *)date message:(NSString *)message repeatInterval:(NSString *)repeatInterval {
    
    NSDate *thisDate = date;

    NSManagedObjectContext *managedObjectContext = [[SMS sharedInstance] managedObjectContext];
    
    SMS *sms = [NSEntityDescription insertNewObjectForEntityForName:@"SMS" inManagedObjectContext:managedObjectContext];
    
    NSString *recepientsString = [recepients componentsJoinedByString:@""];
    
    sms.recepientName = recepientsString;
    
    sms.text = message;
    sms.date = thisDate;
    
    sms.repeatInterval = repeatInterval;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:phones];
    
    sms.recepientNumbers = data;
    
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [[NSCalendar currentCalendar] dateFromComponents:[[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:thisDate]];
    localNotification.alertBody = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"SendSMSToKey", nil), recepientsString];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.userInfo = @{@"date" : thisDate, @"recepients" : recepientsString};
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    if ([repeatInterval isEqualToString:NSLocalizedString(@"DailyRepeatKey", nil)]) {
        localNotification.repeatInterval = NSCalendarUnitDay;
    } else if ([repeatInterval isEqualToString:NSLocalizedString(@"WeeklyRepeatKey", nil)]) {
        localNotification.repeatInterval = NSCalendarUnitWeekOfYear;
    } else if ([repeatInterval isEqualToString:NSLocalizedString(@"MonthlyRepeatKey", nil)]) {
        localNotification.repeatInterval = NSCalendarUnitMonth;
    } else if ([repeatInterval isEqualToString:NSLocalizedString(@"YearlyRepeatKey", nil)]) {
        localNotification.repeatInterval = NSCalendarUnitYear;
    } else if ([repeatInterval isEqualToString:NSLocalizedString(@"NeverRepeatKey", nil)]) {
        
    }
}

- (void)rescheduleSMS:(SMS *)sms {

    NSManagedObjectContext *managedObjectContext = [[SMS sharedInstance] managedObjectContext];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    
    if ([sms.repeatInterval isEqualToString:NSLocalizedString(@"DailyRepeatKey", nil)]) {
        
        [dateComponents setDay:1];
        
    } else if ([sms.repeatInterval isEqualToString:NSLocalizedString(@"WeeklyRepeatKey", nil)]) {

        [dateComponents setWeekOfYear:1];

    } else if ([sms.repeatInterval isEqualToString:NSLocalizedString(@"MonthlyRepeatKey", nil)]) {

        [dateComponents setMonth:1];

    } else if ([sms.repeatInterval isEqualToString:NSLocalizedString(@"YearlyRepeatKey", nil)]) {

        [dateComponents setYear:1];
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *newDate = [calendar dateByAddingComponents:dateComponents toDate:sms.date options:0];
    
    sms.date = newDate;
    
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
    
    NSArray *phones = [NSKeyedUnarchiver unarchiveObjectWithData:sms.recepientNumbers];
    
    NSArray *names = [sms.recepientName componentsSeparatedByString:@", "];
    
    [self scheduleSMSWithRecepients:names phones:phones date:sms.date message:sms.text repeatInterval:sms.repeatInterval];
}

@end
