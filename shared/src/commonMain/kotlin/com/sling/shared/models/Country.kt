package com.sling.shared.models

import kotlinx.serialization.Serializable

/**
 * Represents a country with its dial code and flag
 */
@Serializable
data class Country(
    val name: String,
    val code: String,       // ISO country code (e.g., "GB")
    val dialCode: String,   // Phone dial code (e.g., "+44")
    val flag: String        // Emoji flag (e.g., "🇬🇧")
) {
    /**
     * Asset name for flag image (e.g., "FlagGB")
     */
    val flagAsset: String
        get() = "Flag$code"
    
    companion object {
        /**
         * All supported countries
         */
        val all: List<Country> = listOf(
            Country("Australia", "AU", "+61", "🇦🇺"),
            Country("Brazil", "BR", "+55", "🇧🇷"),
            Country("Canada", "CA", "+1", "🇨🇦"),
            Country("China", "CN", "+86", "🇨🇳"),
            Country("France", "FR", "+33", "🇫🇷"),
            Country("Germany", "DE", "+49", "🇩🇪"),
            Country("Hong Kong", "HK", "+852", "🇭🇰"),
            Country("India", "IN", "+91", "🇮🇳"),
            Country("Ireland", "IE", "+353", "🇮🇪"),
            Country("Italy", "IT", "+39", "🇮🇹"),
            Country("Japan", "JP", "+81", "🇯🇵"),
            Country("Kenya", "KE", "+254", "🇰🇪"),
            Country("Mexico", "MX", "+52", "🇲🇽"),
            Country("Netherlands", "NL", "+31", "🇳🇱"),
            Country("New Zealand", "NZ", "+64", "🇳🇿"),
            Country("Nigeria", "NG", "+234", "🇳🇬"),
            Country("Singapore", "SG", "+65", "🇸🇬"),
            Country("South Africa", "ZA", "+27", "🇿🇦"),
            Country("Spain", "ES", "+34", "🇪🇸"),
            Country("Switzerland", "CH", "+41", "🇨🇭"),
            Country("United Arab Emirates", "AE", "+971", "🇦🇪"),
            Country("United Kingdom", "GB", "+44", "🇬🇧"),
            Country("United States", "US", "+1", "🇺🇸")
        )
        
        /**
         * Search countries by name
         */
        fun search(query: String): List<Country> {
            if (query.isEmpty()) return all
            return all.filter { it.name.contains(query, ignoreCase = true) }
        }
        
        /**
         * Find country by code
         */
        fun byCode(code: String): Country? {
            return all.find { it.code.equals(code, ignoreCase = true) }
        }
    }
}

/**
 * Month data for birthday selection
 */
@Serializable
data class Month(
    val id: Int,
    val name: String,
    val shortName: String
) {
    companion object {
        val all: List<Month> = listOf(
            Month(1, "January", "Jan"),
            Month(2, "February", "Feb"),
            Month(3, "March", "Mar"),
            Month(4, "April", "Apr"),
            Month(5, "May", "May"),
            Month(6, "June", "Jun"),
            Month(7, "July", "Jul"),
            Month(8, "August", "Aug"),
            Month(9, "September", "Sep"),
            Month(10, "October", "Oct"),
            Month(11, "November", "Nov"),
            Month(12, "December", "Dec")
        )
    }
}
