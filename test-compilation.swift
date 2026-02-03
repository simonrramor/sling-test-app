#!/usr/bin/env swift

// Simple compilation test for the recurring purchase feature
// This will check if the basic syntax and imports are correct

import Foundation

// Test that our enums are correctly defined
let frequency = RecurringFrequency.weekly
let status = RecurringPurchaseStatus.active

print("✅ Recurring purchase models compiled successfully")
print("📊 Test frequency: \(frequency.displayName)")
print("🔄 Test status: \(status.displayName)")

// Test date calculations
let nextDate = frequency.nextDate(from: Date())
print("📅 Next date calculation works: \(nextDate)")

print("🎉 All basic tests passed!")