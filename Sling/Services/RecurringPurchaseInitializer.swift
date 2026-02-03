import Foundation

/// Initializes demo recurring purchases for testing and demonstration
class RecurringPurchaseInitializer {
    static let shared = RecurringPurchaseInitializer()
    
    private init() {}
    
    /// Set up demo recurring purchases if none exist
    func setupDemoRecurringPurchasesIfNeeded() {
        let recurringService = RecurringPurchaseService.shared
        
        // Only set up demo data if no recurring purchases exist
        guard recurringService.recurringPurchases.isEmpty else {
            print("📊 Recurring purchases already exist, skipping demo setup")
            return
        }
        
        print("🚀 Setting up demo recurring purchases...")
        
        // Apple - Weekly $50
        var applePurchase = RecurringPurchase(
            stockIconName: "StockApple",
            stockSymbol: "AAPL",
            stockName: "Apple Inc",
            amount: 50.0,
            frequency: .weekly
        )
        
        // Tesla - Monthly $100
        var teslaPurchase = RecurringPurchase(
            stockIconName: "StockTesla", 
            stockSymbol: "TSLA",
            stockName: "Tesla Inc",
            amount: 100.0,
            frequency: .monthly
        )
        
        // Microsoft - Biweekly $75
        var microsoftPurchase = RecurringPurchase(
            stockIconName: "StockMicrosoft",
            stockSymbol: "MSFT", 
            stockName: "Microsoft",
            amount: 75.0,
            frequency: .biweekly
        )
        
        // Simulate some historical purchases for demo
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date()
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        // Apple - had 2 purchases already
        applePurchase.recordPurchase(purchaseDate: oneWeekAgo)
        applePurchase.recordPurchase(purchaseDate: twoWeeksAgo)
        
        // Tesla - had 1 purchase
        teslaPurchase.recordPurchase(purchaseDate: oneMonthAgo)
        
        // Microsoft - had 1 purchase 
        microsoftPurchase.recordPurchase(purchaseDate: twoWeeksAgo)
        
        // Add to service
        recurringService.addRecurringPurchase(applePurchase)
        recurringService.addRecurringPurchase(teslaPurchase)
        recurringService.addRecurringPurchase(microsoftPurchase)
        
        // Create some execution history
        createDemoExecutionHistory(for: applePurchase, dates: [oneWeekAgo, twoWeeksAgo])
        createDemoExecutionHistory(for: teslaPurchase, dates: [oneMonthAgo])
        createDemoExecutionHistory(for: microsoftPurchase, dates: [twoWeeksAgo])
        
        print("✅ Demo recurring purchases set up successfully!")
        print("  • Apple: Weekly $50 (2 purchases completed)")
        print("  • Tesla: Monthly $100 (1 purchase completed)")
        print("  • Microsoft: Biweekly $75 (1 purchase completed)")
    }
    
    private func createDemoExecutionHistory(for purchase: RecurringPurchase, dates: [Date]) {
        let recurringService = RecurringPurchaseService.shared
        let ondoService = OndoService.shared
        
        for _ in dates {
            // Get a simulated price for the date
            let basePrice = ondoService.tokenData[purchase.stockIconName]?.currentPrice ?? 150.0
            let priceVariation = Double.random(in: 0.9...1.1) // ±10% variation
            let historicalPrice = basePrice * priceVariation
            
            let sharesOwned = purchase.amount / historicalPrice
            
            let execution = RecurringPurchaseExecution(
                recurringPurchaseId: purchase.id,
                amount: purchase.amount,
                pricePerShare: historicalPrice,
                shares: sharesOwned,
                stockIconName: purchase.stockIconName,
                stockSymbol: purchase.stockSymbol,
                success: true
            )
            
            // Manually set the execution date
            let modifiedExecution = RecurringPurchaseExecution(
                recurringPurchaseId: execution.recurringPurchaseId,
                amount: execution.amount,
                pricePerShare: execution.pricePerShare,
                shares: execution.shares,
                stockIconName: execution.stockIconName,
                stockSymbol: execution.stockSymbol,
                success: execution.success
            )
            
            recurringService.executionHistory.append(modifiedExecution)
        }
        
        // Save the execution history
        if let encoded = try? JSONEncoder().encode(recurringService.executionHistory) {
            UserDefaults.standard.set(encoded, forKey: "recurringPurchaseExecutions")
        }
    }
    
    /// Force check and execute any due purchases (for testing)
    func forcePurchaseExecution() {
        print("🔄 Force checking for due recurring purchases...")
        RecurringPurchaseService.shared.checkAndExecutePurchases()
    }
    
    /// Add sufficient cash balance for testing
    func ensureSufficientFundsForTesting() {
        let portfolioService = PortfolioService.shared
        let currentBalance = portfolioService.cashBalance
        let minimumBalance: Double = 1000 // £1000 for testing
        
        if currentBalance < minimumBalance {
            let amountToAdd = minimumBalance - currentBalance
            portfolioService.addCash(amountToAdd)
            print("💰 Added £\(Int(amountToAdd)) to wallet for recurring purchase testing")
            print("💳 Current balance: £\(Int(portfolioService.cashBalance))")
        } else {
            print("💳 Sufficient balance available: £\(Int(currentBalance))")
        }
    }
}

// MARK: - App Launch Integration

extension RecurringPurchaseInitializer {
    /// Call this from the app's initialization to set up demo data and ensure functionality
    func initializeForDemo() {
        ensureSufficientFundsForTesting()
        setupDemoRecurringPurchasesIfNeeded()
        
        // Schedule a demo purchase check in 5 seconds (so Simon can see it working)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.forcePurchaseExecution()
        }
    }
}