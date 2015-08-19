//
//  DBTAppDelegate.m
//  DBTest
//
//  Created by kevin delord on 16/06/14.
//  Copyright (c) 2014 kevin delord. All rights reserved.
//

#import "DBTAppDelegate.h"

@implementation DBTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    DKDBManager.verbose = YES;
    DKDBManager.resetStoredEntities = YES;
    BOOL didResetDB = [DKDBManager setupDatabaseWithName:@"DB.sqlite"];
    if (didResetDB) {
        // The database is fresh new.
        // Depending on your needs you might want to do something special right now as:.
        // - Setting up some user defaults.
        // - Deal with your api/store manager.
        // etc.
    }
    // Starting this point your database is ready to use.
    // You can now create any object you could need.

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [DKDBManager cleanUp];
}

@end
