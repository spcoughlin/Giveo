//
//  SavedUIViewTests.swift
//  swipeappUITests
//
//  Created by Alec Agayan on 2/4/25.
//

import XCTest

class SavedViewUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        // Stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // Optionally add an argument to indicate UI testing.
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    func testSavedCharitiesListIsDisplayed() {
        // Verify that the navigation title "Saved Charities" is present.
        let navBar = app.navigationBars["Saved Charities"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "The Saved Charities view should be displayed.")
        
        // The list should have been assigned an accessibility identifier.
        let savedTable = app.tables["SavedCharitiesTable"]
        XCTAssertTrue(savedTable.waitForExistence(timeout: 5), "The saved charities table should exist.")
        
        // Check that there is at least one charity cell.
        let firstCell = savedTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "There should be at least one charity cell.")
    }
    
    func testNavigationToCharityDetail() {
        // Assuming the saved charities list is already populated.
        let savedTable = app.tables["SavedCharitiesTable"]
        let firstCell = savedTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "There should be at least one charity cell to tap on.")
        
        // Tap the cell.
        firstCell.tap()
        
        // After tapping, assume that the CharityDetailView has an accessibility identifier set.
        let detailView = app.otherElements["CharityDetailView"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "The charity detail view should be displayed after tapping a charity.")
    }
}
