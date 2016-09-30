//
//  SMS.h
//  SMS Scheduler
//
// Created by ilabafrica on 24/08/2016.
// Copyright © 2016 Strathmore. All rights reserved.

//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SMS : NSManagedObject

+ (SMS *)sharedInstance;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)clearData;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

#import "SMS+CoreDataProperties.h"