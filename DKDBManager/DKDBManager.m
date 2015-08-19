//
//  DKDBManager.m
//
//  Created by kevin delord on 21/02/14.
//  Copyright (c) 2014 Kevin Delord. All rights reserved.
//

#import "DKDBManager.h"

static BOOL _allowUpdate = YES;
static BOOL _verbose = NO;
static BOOL _resetStoredEntities = NO;
static BOOL _needForcedUpdate = NO;

@interface DKDBManager () {
    NSMutableDictionary *   _entities;
    NSManagedObjectContext *_context;
}

@end

@implementation DKDBManager

#pragma mark - init method

- (instancetype)init {
    self = [super init];
    if (self) {
        _entities = [NSMutableDictionary new];
        _context = nil;
    }
    return self;
}

#pragma mark - DB methods

+ (instancetype)sharedInstance {
    static DKDBManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [DKDBManager new];
    });
    return manager;
}

+ (NSArray *)entities {
    NSMutableArray *classNames = [NSMutableArray new];
    for (NSEntityDescription *desc in [NSManagedObjectModel MR_defaultManagedObjectModel].entities) {
        if (desc.isAbstract == false) {
            [classNames addObject:desc.managedObjectClassName];
        }
    }
    return classNames;
}

+ (NSUInteger)count {
    // This method is needed to make the compiler understands this method exists for the NSManagedObject classes.
    // See: DKDBManager::dump and DKDBManager::dumpCount
    return 0;
}

+ (NSArray *)all {
    // This method is needed to make the compiler understands this method exists for the NSManagedObject classes.
    // See: DKDBManager::dump and DKDBManager::dumpCount
    return nil;
}

+ (BOOL)setupDatabaseWithName:(NSString *)databaseName {

    // Refresh current/default log level
    self.verbose = self.verbose;

    // Boolean to know if the database has been completely reset
    BOOL didResetDB = NO;
    if (DKDBManager.resetStoredEntities) {
        didResetDB = [self eraseDatabaseForStoreName:databaseName];
    }

    // Setup the coredata stack
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:databaseName];

    return didResetDB;
}

#pragma mark - Delete methods

+ (BOOL)eraseDatabaseForStoreName:(NSString *)databaseName {

    CRUDLog(DKDBManager.verbose, @"erase database: %@", databaseName);
    // do some cleanUp of MagicalRecord
    [self cleanUp];

    // remove the sqlite file
    BOOL didResetDB = YES;
    NSError *error;
    NSURL *fileURL = [NSPersistentStore MR_urlForStoreName:databaseName];
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
    if (error && error.code != NSFileNoSuchFileError) {
        [[[UIAlertView alloc] initWithTitle:@"Error - cannot erase DB" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil] show];
        didResetDB = NO;
    }
    return didResetDB;
}

+ (void)removeDeprecatedEntities {
    DKDBManager *manager = [DKDBManager sharedInstance];

    CRUDLog(self.verbose, @"-------------- Removing deprecated entities -----------------");

    for (NSString *className in self.entities) {
        Class class = NSClassFromString(className);
        [class removeDeprecatedEntitiesFromArray:manager->_entities[className]];
    }
}

+ (void)deleteAllEntities {
    for (NSString *className in self.entities) {
        Class class = NSClassFromString(className);
        [class deleteAllEntities];
    }
    [self dump];
}

+ (void)deleteAllEntitiesForClass:(Class)class {
    if ([self.entities containsObject:NSStringFromClass(class)]){
        [class deleteAllEntities];
    }
    [self dump];
}

#pragma mark - Save methods

+ (void)saveEntityAsNotDeprecated:(id)entity {

    DKDBManager *manager = [DKDBManager sharedInstance];

    NSString *className = NSStringFromClass([entity class]);

    if (!manager->_entities[className]) {
        [manager->_entities setValue:[NSMutableArray new] forKey:className];
    }

    if ([entity respondsToSelector:@selector(uniqueIdentifier)]) {
        [manager->_entities[className] addObject:[entity performSelector:@selector(uniqueIdentifier)]];
    }
}

#pragma mark - Asynchronous context saving

+ (void)saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block {
    [super saveWithBlock:^(NSManagedObjectContext *localContext) {
        if (block != nil) {
            block(localContext);
        }
        [self dump];
    }];
}

+ (void)saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(MRSaveCompletionHandler)completion {
    [super saveWithBlock:block completion:^(BOOL contextDidSave, NSError *error) {
        [self dump];
        if (completion != nil) {
            completion(contextDidSave, error);
        }
    }];
}

#pragma mark - Synchronous context saving

+ (void)saveWithBlockAndWait:(void(^)(NSManagedObjectContext *localContext))block {
    [super saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        if (block != nil) {
            block(localContext);
        }
        [self dump];
    }];
}

#pragma mark - Deprecated Methods — DO NOT USE

+ (void)save {
    [self saveToPersistentStoreWithCompletion:nil];
}

+ (void)saveToPersistentStoreWithCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {        
        [self dump];
        if (completionBlock) {
            completionBlock(success, error);
        }
    }];
#pragma clang diagnostic pop
}

+ (void)saveToPersistentStoreAndWait {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    [self dump];
#pragma clang diagnostic pop
}

#pragma mark - DEBUG methods

// verbose
+ (void)setVerbose:(BOOL)verbose {
    _verbose = verbose;

    NSUInteger logLevel = MagicalRecordLoggingLevelOff;
    if (_verbose == true) {
#ifdef DEBUG
        logLevel = MagicalRecordLoggingLevelDebug;
#else
        logLevel = MagicalRecordLoggingLevelError;
#endif
    }
    [MagicalRecord setLoggingLevel:logLevel];
}

+ (BOOL)verbose {
    return _verbose;
}

// allow update
+ (BOOL)allowUpdate {
    return _allowUpdate;
}

+ (void)setAllowUpdate:(BOOL)allowUpdate {
    _allowUpdate = allowUpdate;
}

// reset stored entities
+ (BOOL)resetStoredEntities {
    return _resetStoredEntities;
}

+ (void)setResetStoredEntities:(BOOL)resetStoredEntities {
    _resetStoredEntities = resetStoredEntities;
}

// need forced update
+ (BOOL)needForcedUpdate {
    return _needForcedUpdate;
}

+ (void)setNeedForcedUpdate:(BOOL)needForcedUpdate {
    _needForcedUpdate = needForcedUpdate;
}

#pragma mark - Log

+ (void)dumpCount {

    if (self.verbose == false) {
        return ;
    }

    NSString *count = @"";

    for (NSString *className in self.entities) {
        Class class = NSClassFromString(className);
        count = [NSString stringWithFormat:@"%@%ld %@, ", count, (unsigned long)(class.count), className];
    }

    CRUDLog(self.verbose, @"-------------------------------------");
    CRUDLog(self.verbose, @"%@", count);
    CRUDLog(self.verbose, @"-------------------------------------");
}

+ (void)dump {

    if (self.verbose == false) {
        return ;
    }

    [self dumpCount];

    for (NSString *className in self.entities) {
        Class class = NSClassFromString(className);
        if (class.verbose) {
            for (id entity in class.all)
                NSLog(@"%@ %@", className, entity);
            CRUDLog(self.verbose, @"-------------------------------------");
        }
    }
}

@end
