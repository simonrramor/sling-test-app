package com.sling.shared.platform

import android.content.Context
import android.content.SharedPreferences

/**
 * Android implementation of PersistenceDriver using SharedPreferences
 */
actual class PersistenceDriver(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "sling_prefs",
        Context.MODE_PRIVATE
    )
    
    actual fun saveString(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }
    
    actual fun getString(key: String): String? {
        return prefs.getString(key, null)
    }
    
    actual fun saveBoolean(key: String, value: Boolean) {
        prefs.edit().putBoolean(key, value).apply()
    }
    
    actual fun getBoolean(key: String, defaultValue: Boolean): Boolean {
        return prefs.getBoolean(key, defaultValue)
    }
    
    actual fun saveDouble(key: String, value: Double) {
        // SharedPreferences doesn't support Double directly, use Long bits
        prefs.edit().putLong(key, value.toRawBits()).apply()
    }
    
    actual fun getDouble(key: String, defaultValue: Double): Double {
        return if (prefs.contains(key)) {
            Double.fromBits(prefs.getLong(key, defaultValue.toRawBits()))
        } else {
            defaultValue
        }
    }
    
    actual fun remove(key: String) {
        prefs.edit().remove(key).apply()
    }
    
    actual fun clear() {
        prefs.edit().clear().apply()
    }
}
