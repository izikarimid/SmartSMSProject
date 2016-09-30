//
//  SMS+CoreDataProperties.h
//  SMS Scheduler

//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//
//Created by ilabafrica on 24/08/2016.
// Copyright © 2016 Strathmore. All rights reserved.




#import "SMS.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMS (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString    *recepientName;
@property (nullable, nonatomic, retain) NSString    *repeatInterval;
@property (nullable, nonatomic, retain) NSData      *recepientNumbers;
@property (nullable, nonatomic, retain) NSDate      *date;
@property (nullable, nonatomic, retain) NSString    *text;
@property (nonatomic)                   BOOL        sent;

@end

NS_ASSUME_NONNULL_END
