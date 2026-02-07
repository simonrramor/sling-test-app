package com.sling.shared.platform

import platform.Foundation.NSUserDefaults

/**
 * iOS implementation of PersistenceDriver using NSUserDefaults
 */
actual class PersistenceDriver {
    private val defaults = NSUserDefaults.standardUserDefaults
    
    actual fun saveString(key: String, value: String) {
        defaults.setObject(value, forKey = key)
        defaults.synchronize()
    }
    
    actual fun getString(key: String): String? {
        return defaults.stringForKey(key)
    }
    
    actual fun saveBoolean(key: String, value: Boolean) {
        defaults.setBool(value, forKey = key)
        defaults.synchronize()
    }
    
    actual fun getBoolean(key: String, defaultValue: Boolean): Boolean {
        return if (defaults.objectForKey(key) != null) {
            defaults.boolForKey(key)
        } else {
            defaultValue
        }
    }
    
    actual fun saveDouble(key: String, value: Double) {
        defaults.setDouble(value, forKey = key)
        defaults.synchronize()
    }
    
    actual fun getDouble(key: String, defaultValue: Double): Double {
        return if (defaults.objectForKey(key) != null) {
            defaults.doubleForKey(key)
        } else {
            defaultValue
        }
    }
    
    actual fun remove(key: String) {
        defaults.removeObjectForKey(key)
        defaults.synchronize()
    }
    
    actual fun clear() {
        val appDomain = platform.Foundation.NSBundle.mainBundle.bundleIdentifier
        if (appDomain != null) {
            defaults.removePersistentDomainForName(appDomain)
            defaults.synchronize()
        }
    }
}
