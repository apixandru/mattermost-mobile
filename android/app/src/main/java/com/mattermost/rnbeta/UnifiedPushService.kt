// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

package com.mattermost.rnbeta

import android.os.Bundle
import android.util.Base64
import com.facebook.react.ReactApplication
import com.wix.reactnativenotifications.core.JsIOHelper
import com.wix.reactnativenotifications.core.notification.PushNotification
import org.json.JSONObject
import org.unifiedpush.android.connector.FailedReason
import org.unifiedpush.android.connector.PushService
import org.unifiedpush.android.connector.data.PushEndpoint
import org.unifiedpush.android.connector.data.PushMessage

// Hardcoded swap (no fdroid/Firebase-removal decision yet, see
// docs/unified-push-integration-plan.md Phase 3a) — Android only.
class UnifiedPushService : PushService() {

    override fun onNewEndpoint(endpoint: PushEndpoint, instance: String) {
        val bundleJson = JSONObject().apply {
            put("endpoint", endpoint.url)
            put("p256dh", endpoint.pubKeySet?.pubKey ?: "")
            put("auth", endpoint.pubKeySet?.auth ?: "")
        }.toString().toByteArray(Charsets.UTF_8)

        val token = "unified_push-v2:" + Base64.encodeToString(
            bundleJson,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING
        )

        sendTokenToJS(token)
    }

    override fun onMessage(message: PushMessage, instance: String) {
        val json = JSONObject(String(message.content, Charsets.UTF_8))
        val bundle = Bundle()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            bundle.putString(key, json.getString(key))
        }

        try {
            PushNotification.get(applicationContext, bundle).onReceived()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onRegistrationFailed(reason: FailedReason, instance: String) {
        // No-op for now. Surfacing this to JS is a Phase 3 hardening item — see
        // docs/unified-push-integration-plan.md.
    }

    override fun onUnregistered(instance: String) {
        // No-op for now — see onRegistrationFailed.
    }

    private fun sendTokenToJS(token: String) {
        val appContext = applicationContext
        if (appContext !is ReactApplication) {
            return
        }

        val reactContext = appContext.reactHost?.currentReactContext
        if (reactContext != null && reactContext.hasActiveReactInstance()) {
            val payload = Bundle().apply { putString("token", token) }
            JsIOHelper().sendEventToJS("UNIFIED_PUSH_TOKEN_RECEIVED", payload, reactContext)
        }
    }
}
