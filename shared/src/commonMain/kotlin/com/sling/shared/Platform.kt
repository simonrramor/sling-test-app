package com.sling.shared

/**
 * Platform identification for KMP
 */
expect fun getPlatform(): Platform

interface Platform {
    val name: String
}
