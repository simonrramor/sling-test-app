import Foundation

// MARK: - Receipt Item

struct ReceiptItem: Identifiable {
    let id = UUID()
    var name: String
    var price: Double
    var assignedTo: [Contact] // Multiple people can share an item
    
    var formattedPrice: String {
        price.asGBP
    }
    
    var isAssigned: Bool {
        !assignedTo.isEmpty
    }
}

// MARK: - Scanned Receipt

struct ScannedReceipt {
    var items: [ReceiptItem]
    var tax: Double?
    var tip: Double?
    var total: Double
    
    var formattedTotal: String {
        total.asGBP
    }
    
    var formattedTax: String? {
        guard let tax = tax else { return nil }
        return tax.asGBP
    }
    
    var formattedTip: String? {
        guard let tip = tip else { return nil }
        return tip.asGBP
    }
    
    // Calculate how much each person owes based on assigned items
    func amountPerPerson() -> [Contact: Double] {
        var amounts: [UUID: (contact: Contact, amount: Double)] = [:]
        
        for item in items {
            guard !item.assignedTo.isEmpty else { continue }
            
            // Split item price among assigned people
            let splitPrice = item.price / Double(item.assignedTo.count)
            
            for contact in item.assignedTo {
                if let existing = amounts[contact.id] {
                    amounts[contact.id] = (existing.contact, existing.amount + splitPrice)
                } else {
                    amounts[contact.id] = (contact, splitPrice)
                }
            }
        }
        
        // Convert to dictionary keyed by Contact
        var result: [Contact: Double] = [:]
        for (_, value) in amounts {
            result[value.contact] = value.amount
        }
        
        return result
    }
    
    // Get items assigned to a specific contact
    func items(for contact: Contact) -> [ReceiptItem] {
        items.filter { item in
            item.assignedTo.contains { $0.id == contact.id }
        }
    }
    
    // Check if all items are assigned
    var allItemsAssigned: Bool {
        items.allSatisfy { $0.isAssigned }
    }
    
    // Count of assigned items
    var assignedItemsCount: Int {
        items.filter { $0.isAssigned }.count
    }
}

// MARK: - Contact Extension for Hashable

extension Contact: Hashable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
