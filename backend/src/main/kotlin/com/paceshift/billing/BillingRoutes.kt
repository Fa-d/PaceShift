package com.paceshift.billing

import com.paceshift.Config
import com.paceshift.auth.JWT_AUTH
import com.paceshift.auth.UserRepository
import com.paceshift.auth.userId
import io.ktor.http.HttpStatusCode
import io.ktor.server.auth.authenticate
import io.ktor.server.request.header
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.route
import kotlinx.serialization.Serializable

@Serializable
data class EntitlementResponse(val proEntitled: Boolean)

/**
 * Minimal RevenueCat webhook payload — we only need the app user id (the email
 * we set as RevenueCat's appUserID) and the event type to flip entitlement.
 */
@Serializable
data class RevenueCatWebhook(val event: RevenueCatEvent)

@Serializable
data class RevenueCatEvent(
    val type: String,
    val app_user_id: String,
    val entitlement_ids: List<String> = emptyList(),
)

fun Route.billingRoutes() {
    // Server-to-server webhook from RevenueCat. Auth via a shared bearer token.
    post("/billing/webhook") {
        val expected = Config.revenueCatAuthToken
        val provided = call.request.header("Authorization")?.removePrefix("Bearer ")?.trim()
        if (expected != null && provided != expected) {
            call.respond(HttpStatusCode.Unauthorized)
            return@post
        }
        val body = call.receive<RevenueCatWebhook>()
        val grant = when (body.event.type) {
            "INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE", "UNCANCELLATION" ->
                body.event.entitlement_ids.contains(Config.proEntitlementId) ||
                    body.event.entitlement_ids.isEmpty()
            "CANCELLATION", "EXPIRATION", "SUBSCRIPTION_PAUSED" -> false
            else -> null
        }
        if (grant != null) {
            UserRepository.setProEntitledByEmail(body.event.app_user_id, grant)
        }
        call.respond(HttpStatusCode.OK)
    }

    authenticate(JWT_AUTH) {
        route("/billing") {
            get("/entitlement") {
                val user = UserRepository.findById(call.userId())
                call.respond(EntitlementResponse(user?.proEntitled ?: false))
            }
        }
    }
}
