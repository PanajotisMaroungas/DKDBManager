//
//  NSmanagedContext+DKDBManagerTest.swift
//  DKDBManager
//
//  Created by Panajotis Maroungas on 01/02/16.
//  Copyright © 2016 Smart Mobile Factory. All rights reserved.
//

import XCTest

class NSmanagedContext_DKDBManagerTest: XCTestCase {
    
    override func setUp() {

		super.setUp()

		MockDBManagerForMockObjects.setDefaultModelFromClass(self.classForCoder)
		MockDBManagerForMockObjects.setupCoreDataStackWithInMemoryStore()

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		
        super.tearDown()
    }
}

// MARK: - CREATE

extension NSmanagedContext_DKDBManagerTest {

	func testCreateEntityFromDictionaryWithCompletion() {

		MockDBManagerForMockObjects.saveWithBlock { (managedContext) -> Void in

			// SET
			let demoDict 			= MockManager.randomPassengerJSON()[0]

			// CALL
			let persistedPassenger 	= Passenger.createEntityFromDictionary(demoDict, inContext: managedContext, completion: nil)

			// ASSERT
			let equalName		= ((demoDict[JSON.Name] as? String) ?? "" == (persistedPassenger?.name) ?? 0)

			XCTAssertTrue(equalName == true)
		}
	}

	func testCreateEntityFromDictionary() {

		MockDBManagerForMockObjects.saveWithBlock { (managedContext) -> Void in

			// SET
			let demoDict 			= MockManager.randomPassengerJSON()[0]

			// CALL
			let persistedPassenger 	= Passenger.createEntityFromDictionary(demoDict, inContext: managedContext)

			// ASSERT
			let equalName			= ((demoDict[JSON.Name] as? String) ?? "" == (persistedPassenger?.name) ?? 0)
			let hasOnlyOneElement 	= (Passenger.MR_findAllInContext(managedContext)?.count == 1)

			XCTAssertTrue(equalName == true && hasOnlyOneElement == true)
		}
	}

	func testCreateEntityInContext() {

		MockDBManagerForMockObjects.saveWithBlock { (managedContext) -> Void in

			// SET + CALL
			let persistedEmptyPassenger = Passenger.createEntityInContext(managedContext)

			var persistedEmptyPassengerIsNill  = false

			if persistedEmptyPassenger == nil {
				persistedEmptyPassengerIsNill = true
			}
			
			//ASSERT
			XCTAssertTrue(persistedEmptyPassengerIsNill == true)
		}
	}
}

// MARK: - DELETE

extension NSmanagedContext_DKDBManagerTest {

	func testDeleteAllObjectsInContext() {

		MockDBManagerForMockObjects.saveWithBlock { (managedContext) -> Void in

			// SET
			let demoDict 			= MockManager.randomPassengerJSON()

			// CALL
			Passenger.createEntitiesFromArray(demoDict, inContext: managedContext)
			let hadObjects			= (Passenger.MR_findAllInContext(managedContext)?.count > 0)
			Passenger.deleteAllEntitiesInContext(managedContext)
			let hasOnlyOneElement 	= (Passenger.MR_findAllInContext(managedContext)?.count == 0)

			// ASSERT
			XCTAssertTrue(hadObjects == true && hasOnlyOneElement == true)
		}
	}

	func testDeleteAllEntitiesForClassInContext() {

		MockDBManagerForMockObjects.saveWithBlock { (managedContext) -> Void in

			// SET
			let demoDict 			= MockManager.randomPassengerJSON()

			// CALL
			Passenger.createEntitiesFromArray(demoDict, inContext: managedContext)
			let hadObjects			= (Passenger.MR_findAllInContext(managedContext)?.count > 0)
			MockDBManagerForMockObjects.deleteAllEntitiesForClass(Passenger.classForCoder(), inContext: managedContext)
			let hasOnlyOneElement 	= (Passenger.MR_findAllInContext(managedContext)?.count == 0)

			// ASSERT
			XCTAssertTrue(hadObjects == true && hasOnlyOneElement == true)
		}
	}
}

// MARK: - SAVE

extension NSmanagedContext_DKDBManagerTest {

	func saveEntityAfterCreationEntityWithStatus() {

		MockDBManagerForMockObjects.saveWithBlock { (managedContext) -> Void in

			// SET
			let demoDict 			= MockManager.randomPassengerJSON()[0]

			// CALL
			let persistedPassenger 	= Passenger.createEntityFromDictionary(demoDict, inContext: managedContext)
			Passenger.deleteAllEntitiesInContext(managedContext)
			let objectDeleted = (Passenger.MR_findAllInContext(managedContext)?.count == 0)
			persistedPassenger?.saveEntityAsNotDeprecated()

			// ASSERT
			let hasOnlyOneElement 	= (Passenger.MR_findAllInContext(managedContext)?.count == 1)

			XCTAssertTrue(objectDeleted == true && hasOnlyOneElement == true)
		}
	}
}

class MockDBManagerForMockObjects: DKDBManager {

}

