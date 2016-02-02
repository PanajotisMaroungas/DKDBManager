//
//  DKDBManagerTest.swift
//  DKDBManager
//
//  Created by Panajotis Maroungas on 29/01/16.
//  Copyright © 2016 Smart Mobile Factory. All rights reserved.
//

import XCTest
import MagicalRecord

class DKDBManagerTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
		MockDBManager.reset()

		super.tearDown()
    }
}

// MARK: - Testing DB Methods

// MARK: - Testing EntityClass

extension DKDBManagerTest {

	func testEntityClassNames() {

		// Set
		MockDBManager.addDemoEntityWithName("TestClass")
		MockDBManager.addDemoEntityWithName("TestClassA")
		MockDBManager.addDemoEntityWithName("TestClassB")

		// Call + Assert
		XCTAssertEqual(["TestClass","TestClassA","TestClassB"], (MockDBManager.entityClassNames() as? [String]) ?? [])
	}
}

// MARK: - Testing CleanUp

extension DKDBManagerTest {

	func testCleanUpShouldDeleteStoredIdentifiers() {

		// Set + Call
		MockDBManager.cleanUp()

		// Assert
		XCTAssertTrue(MockDBManager.sharedInstance().storedIdentifiers.count == 0)
	}

}

// MARK: - DELETE

extension DKDBManagerTest {

	func testRemoveDeprecatedEntitiesInContext(){

		// Set + Call
		MockDBManager.removeDeprecatedEntitiesInContext(NSManagedObjectContext())

		// Assert
		XCTAssertTrue(MockDBManager.deletedEntities?.count == MockDBManager.entityClassNames().count)
	}
}

// MARK: - Testing Log Methods

// MARK: - Testing setVerbose

extension DKDBManagerTest {

	func testSetVerboseTrue() {

		// Set + Call
		MockDBManager.setVerbose(true)

		// Assert
		XCTAssertEqual(MockDBManager.loggingLevel(), MagicalRecord.loggingLevel())
	}

	func testSetVerboseFalse() {

		// Set + Call
		MockDBManager.setVerbose(false)

		// Assert
		XCTAssertEqual(MockDBManager.loggingLevel(), MagicalRecord.loggingLevel())
	}
}

// MARK: - Testing setupDatabaseWithName

extension DKDBManagerTest  {

	func testSetupDatabaseWithResetSucceed() {

		// Set
		MockDBManager.setResetStoredEntities(true)
		MockDBManager.allowsEraseDatabaseForName = true

		// Call
		MockDBManager.setupDatabaseWithName("TestDB") { () -> Void in
			// db reseted 
		}

		// Assert
		XCTAssertTrue(MockDBManager.didResetDatabaseBlockExecuted == true)
	}

	func testSetupDatabaseWithResetFailsDueWhenStoredEntitiesToFalse() {

		// Set
		MockDBManager.setResetStoredEntities(false)
		MockDBManager.allowsEraseDatabaseForName = true

		// Call
		MockDBManager.setupDatabaseWithName("TestDB") { () -> Void in
			// db reseted
		}

		// Assert
		XCTAssertTrue(MockDBManager.didResetDatabaseBlockExecuted == false)
	}

	func testSetupDatabaseWithResetFailsWhenTheDatabaseCannotBeDeleted() {

		// Set
		MockDBManager.setResetStoredEntities(true)
		MockDBManager.allowsEraseDatabaseForName = false

		// Call
		MockDBManager.setupDatabaseWithName("TestDB") { () -> Void in
			// db reseted
		}

		// Assert
		XCTAssertTrue(MockDBManager.didResetDatabaseBlockExecuted == false)
	}

	func testIfSetupDatabaseDidResetWasCalled() {
		// Set + Call
		MockDBManager.setupDatabaseWithName("TestDB")

		// Assert
		XCTAssertTrue(MockDBManager.setupDatabseDidResetCalled == true)
	}

}

// MARK: - Testing dumpCount

extension DKDBManagerTest {

	func testCalldumpCountWithVerbose() {

		// Set
		MockDBManager.setVerbose(true)

		// Call
		MockDBManager.dumpCount()

		// Assert
		XCTAssertTrue(MockDBManager.dumpCountInContextIsCalled == true)
	}

	func testCalldumpCountWithoutVerbose() {

		// Set
		MockDBManager.setVerbose(false)

		// Call
		MockDBManager.dumpCount()

		// Assert
		XCTAssertTrue(MockDBManager.dumpCountInContextIsCalled == false)
	}
}

// MARK: - Testing dump

extension DKDBManagerTest {

	func testCalldumpWithVerbose() {

		// Set
		MockDBManager.setVerbose(true)

		// Call
		MockDBManager.dump()

		// Assert
		XCTAssertTrue(MockDBManager.dumpInContextIsCalled == true)
	}

	func testCalldumpWithoutVerbose() {

		// Set
		MockDBManager.setVerbose(false)

		// Call
		MockDBManager.dumpCount()

		// Assert
		XCTAssertTrue(MockDBManager.dumpInContextIsCalled == false)
	}
}

// MARK: - MockDBManager subclass of DKDBManager

class MockDBManager : DKDBManager {

	// MARK: -  Static Properties of MockDBManager

	static var context							= NSManagedObjectContext()

	static var dumpCountInContextIsCalled 		= false
	static var dumpInContextIsCalled	 		= false

	static var allowsEraseDatabaseForName   	= false
	static var didResetDatabaseBlockExecuted 	= false

	static var setupDatabseDidResetCalled		= false

	static var demoEntities 					: [NSEntityDescription]?

	static var deletedEntities					: [String]?

	// MARK: - DB Methods

	override class func entityClassNames() -> [AnyObject] {

		var array 					= [AnyObject]()
		var entities 				= NSManagedObjectModel().entities

		if let _demoEntitiesNames = self.demoEntities {
			entities 				= _demoEntitiesNames
		}

		for desc in entities {
			array.append(desc.managedObjectClassName);
		}
		return array
	}

	override class func setupDatabaseWithName(databaseName: String, didResetDatabase: (() -> Void)?) {

		self.setupDatabseDidResetCalled = true

		var didResetDB = false
		if (DKDBManager.resetStoredEntities() == true) {
			didResetDB 				= self.eraseDatabaseForStoreName(databaseName)
		}

		if (didResetDB == true && didResetDatabase != nil) {
			self.didResetDatabaseBlockExecuted = true
		}
	}

	override class func eraseDatabaseForStoreName(databaseName: String) -> Bool {
		return self.allowsEraseDatabaseForName
	}

	// MARK: - Log Methods

	override class func dumpCount() {
		self.dumpCountInContext(self.context)
	}

	override class func dumpCountInContext(context: NSManagedObjectContext) {

		if (self.verbose() == false) {
			self.dumpCountInContextIsCalled = false
			return
		}

		self.dumpCountInContextIsCalled 	= true
	}


	override class func dump() {
		self.dumpInContext(self.context)
	}

	override class func dumpInContext(context: NSManagedObjectContext) {

		if (self.verbose() == false) {
			self.dumpInContextIsCalled 		= false
			return
		}

		self.dumpInContextIsCalled 			= true
	}

	// MARK: - DELETE

	override class func removeDeprecatedEntitiesInContext(context: NSManagedObjectContext) {

		self.deletedEntities = [String]()

		for className in self.entityClassNames() {
				self.deletedEntities?.append((className as? String) ?? "")
		}
	}

	// MARK: - Helpers

	class func addDemoEntityWithName(className: String) {

		if self.demoEntities == nil {
			self.demoEntities 				= [NSEntityDescription]()
		}

		let entity 							= NSEntityDescription()
		entity.managedObjectClassName 		= className
		self.demoEntities?.append(entity)
	}

	class func reset() {
		self.context						= NSManagedObjectContext()
		self.dumpCountInContextIsCalled 	= false
		self.dumpInContextIsCalled	 		= false
		self.allowsEraseDatabaseForName   	= false
		self.didResetDatabaseBlockExecuted 	= false
		self.setupDatabseDidResetCalled		= false
		self.demoEntities?.removeAll()
		self.deletedEntities?.removeAll()
	}
}
