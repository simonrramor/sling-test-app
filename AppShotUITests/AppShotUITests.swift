import XCTest

/// AppShot Automatic Screenshot Capture
/// This UI Test automatically captures screenshots of all app screens
final class AppShotUITests: XCTestCase {
    
    let app = XCUIApplication()
    var screenshotCount = 0
    
    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launchArguments = ["--appshot-mode"]
        app.launch()
        
        // Wait for app to be ready
        sleep(2)
    }
    
    override func tearDownWithError() throws {
        // Screenshots are saved automatically
    }
    
    // MARK: - Main Screenshot Test
    
    func testCaptureAllScreens() throws {
        // Capture the initial home screen
        captureScreenshot(named: "01_Home")
        
        // Try to find and tap on bottom navigation items
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let buttons = tabBar.buttons.allElementsBoundByIndex
            for (index, button) in buttons.enumerated() {
                if button.exists && button.isHittable {
                    button.tap()
                    sleep(1)
                    captureScreenshot(named: String(format: "%02d_Tab_%@", index + 2, sanitize(button.label)))
                }
            }
        }
        
        // Look for common navigation patterns
        captureNavigationScreens()
        
        // Look for buttons that might lead to new screens
        captureButtonScreens()
        
        // Look for list items that might be tappable
        captureListScreens()
        
        print("AppShot: Captured \(screenshotCount) screenshots")
    }
    
    // MARK: - Navigation Discovery
    
    private func captureNavigationScreens() {
        // Look for navigation links and buttons
        let navigationButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'view' OR label CONTAINS[c] 'see' OR label CONTAINS[c] 'open' OR label CONTAINS[c] 'go'"))
        
        for i in 0..<min(navigationButtons.count, 10) {
            let button = navigationButtons.element(boundBy: i)
            if button.exists && button.isHittable {
                let label = button.label
                button.tap()
                sleep(1)
                captureScreenshot(named: "Nav_\(sanitize(label))")
                
                // Try to go back
                goBack()
            }
        }
    }
    
    private func captureButtonScreens() {
        // Look for primary action buttons
        let actionButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'send' OR label CONTAINS[c] 'buy' OR label CONTAINS[c] 'sell' OR label CONTAINS[c] 'transfer' OR label CONTAINS[c] 'settings'"))
        
        for i in 0..<min(actionButtons.count, 15) {
            let button = actionButtons.element(boundBy: i)
            if button.exists && button.isHittable {
                let label = button.label
                button.tap()
                sleep(1)
                captureScreenshot(named: "Action_\(sanitize(label))")
                
                goBack()
            }
        }
    }
    
    private func captureListScreens() {
        // Look for table/list cells
        let cells = app.cells.allElementsBoundByIndex
        
        for i in 0..<min(cells.count, 5) {
            let cell = cells[i]
            if cell.exists && cell.isHittable {
                let label = cell.label.isEmpty ? "Item_\(i)" : cell.label
                cell.tap()
                sleep(1)
                captureScreenshot(named: "Detail_\(sanitize(label))")
                
                goBack()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func captureScreenshot(named name: String) {
        screenshotCount += 1
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        print("AppShot: Captured '\(name)'")
    }
    
    private func goBack() {
        // Try multiple back navigation methods
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists && backButton.isHittable {
            backButton.tap()
            sleep(1)
            return
        }
        
        // Try close button
        let closeButton = app.buttons["Close"]
        if closeButton.exists && closeButton.isHittable {
            closeButton.tap()
            sleep(1)
            return
        }
        
        // Try X button
        let xButton = app.buttons["xmark"]
        if xButton.exists && xButton.isHittable {
            xButton.tap()
            sleep(1)
            return
        }
        
        // Try swipe down for sheets
        app.swipeDown()
        sleep(1)
    }
    
    private func sanitize(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return String(cleaned.prefix(30))
    }
}

// MARK: - Individual Screen Tests
// These can be customized for your specific app

extension AppShotUITests {
    
    func testHomeScreen() throws {
        captureScreenshot(named: "Home")
    }
    
    func testNavigateAllTabs() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else {
            print("AppShot: No tab bar found")
            return
        }
        
        let tabs = tabBar.buttons.allElementsBoundByIndex
        for (index, tab) in tabs.enumerated() {
            if tab.exists && tab.isHittable {
                tab.tap()
                sleep(1)
                captureScreenshot(named: "Tab_\(index + 1)_\(sanitize(tab.label))")
            }
        }
    }
}
