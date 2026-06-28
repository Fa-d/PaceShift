package com.paceshift.ai

import com.paceshift.auth.JWT_AUTH
import io.ktor.server.auth.authenticate
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.post
import io.ktor.server.routing.route

/**
 * AI coaching proxy to Anthropic (Phase 10). Endpoints stay behind JWT auth +
 * a Pro entitlement check; the Anthropic key lives only on the server.
 */
fun Route.aiRoutes() {
    authenticate(JWT_AUTH) {
        route("/ai") {
            post("/explain") {
                requireAiAccess(call)
                val reply = AiService.explain(call.receive())
                call.respond(AiReply(reply))
            }
            post("/chat") {
                requireAiAccess(call)
                val reply = AiService.chat(call.receive())
                call.respond(AiReply(reply))
            }
            post("/ui") {
                requireGenUiAccess(call)
                val spec = GenUiService.compose(call.receive())
                call.respond(spec)
            }
        }
    }
}
