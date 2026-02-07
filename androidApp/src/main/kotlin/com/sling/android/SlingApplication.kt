package com.sling.android

import android.app.Application
import com.sling.shared.platform.PersistenceDriver
import com.sling.shared.services.ServiceLocator

class SlingApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize the shared KMP services
        val persistenceDriver = PersistenceDriver(this)
        ServiceLocator.initialize(persistenceDriver)
    }
}
