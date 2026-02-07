package com.sling.shared.models

import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.Serializable

/**
 * Shared data model for the signup flow
 * Passed between all signup screens to collect user information
 */
@Serializable
data class SignUpData(
    // Step 1: About you
    val firstName: String = "",
    val lastName: String = "",
    val preferredName: String = "",
    
    // Step 2: Birthday
    val birthDay: String = "",
    val birthMonth: String = "",
    val birthYear: String = "",
    
    // Step 3: Country
    val country: String = "",
    val countryCode: String = "+44",
    val countryFlag: String = "FlagGB",
    
    // Step 4: Phone
    val phoneNumber: String = "",
    
    // Step 5: Verification
    val verificationCode: String = "",
    
    // Step 6: Terms & Conditions
    val hasAcceptedTerms: Boolean = false,
    val useESignature: Boolean = false
) {
    /**
     * Full legal name (first + last)
     */
    val fullLegalName: String
        get() = "$firstName $lastName".trim()
    
    /**
     * Display name (preferred or first name)
     */
    val displayName: String
        get() {
            val trimmedPreferred = preferredName.trim()
            return if (trimmedPreferred.isEmpty()) firstName else trimmedPreferred
        }
    
    /**
     * Formatted phone number with country code
     */
    val formattedPhoneNumber: String
        get() = "$countryCode $phoneNumber"
    
    /**
     * Check if birthday is valid (user must be 18+)
     */
    val isBirthdayValid: Boolean
        get() {
            val day = birthDay.toIntOrNull() ?: return false
            val month = birthMonth.toIntOrNull() ?: return false
            val year = birthYear.toIntOrNull() ?: return false
            
            val now = Clock.System.now()
            val today = now.toLocalDateTime(TimeZone.currentSystemDefault())
            val currentYear = today.year
            
            return day in 1..31 && 
                   month in 1..12 && 
                   year in 1900..(currentYear - 18)
        }
    
    /**
     * Check if Step 1 (name) is complete
     */
    val isStep1Complete: Boolean
        get() = firstName.isNotBlank() && lastName.isNotBlank()
    
    /**
     * Check if Step 2 (birthday) is complete
     */
    val isStep2Complete: Boolean
        get() = isBirthdayValid
    
    /**
     * Check if Step 3 (country) is complete
     */
    val isStep3Complete: Boolean
        get() = country.isNotBlank()
    
    /**
     * Check if Step 4 (phone) is complete
     */
    val isStep4Complete: Boolean
        get() = phoneNumber.length >= 10
    
    /**
     * Check if Step 5 (verification) is complete
     */
    val isStep5Complete: Boolean
        get() = verificationCode.length == 6
    
    /**
     * Check if all required fields are complete
     */
    val isComplete: Boolean
        get() = isStep1Complete && 
                isStep2Complete && 
                isStep3Complete && 
                isStep4Complete && 
                isStep5Complete && 
                hasAcceptedTerms
}
