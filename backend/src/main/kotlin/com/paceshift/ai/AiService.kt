package com.paceshift.ai

import com.paceshift.Config
import com.paceshift.auth.UserRepository
import com.paceshift.auth.userId
import com.paceshift.plugins.ApiException
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.ApplicationCall
import kotlinx.serialization.Serializable

/**
 * AI coaching proxy (Phase 10). Returns prose grounded in the engine's actual
 * RescheduleOutcome changelog + the user's plan summary — the model phrases the
 * facts, it does not invent them.
 *
 * Routed through [GlmClient] (GLM via Z.ai), the same provider as [GenUiService],
 * so the backend has no dependency on an Anthropic API key. The key never leaves
 * the server.
 */
object AiService {
    private const val explainSystem =
        "You are PaceShift's running coach. You explain changes the app's " +
            "scheduling engine already made to a runner's training plan. Only use the " +
            "facts provided — never invent runs, dates, or numbers. Be warm, concise " +
            "(2-4 sentences), and reassuring: the plan adapts safely and protects the " +
            "race date. Do not give medical advice."

    private const val chatSystem =
        "You are PaceShift's running coach. Answer the runner's questions using only " +
            "the plan context provided. Be encouraging, practical, and concise. If asked " +
            "for medical or injury advice, suggest consulting a professional."

    private const val emptyReply = "I couldn't generate a response just now."

    /** Explains an engine reshuffle, grounded in the provided change list. */
    suspend fun explain(req: ExplainRequest): String {
        val facts = req.changes.joinToString("\n") { "- $it" }
        val user = buildString {
            appendLine("Plan summary: ${req.planSummary}")
            appendLine()
            appendLine("The engine just made these changes after a missed run:")
            appendLine(facts)
            appendLine()
            append("Explain to the runner what changed and why it keeps them safe.")
        }
        val reply = GlmClient.complete(
            messages = listOf(
                GlmMessage("system", explainSystem),
                GlmMessage("user", user),
            ),
            maxTokens = 500,
        )
        return reply.ifBlank { emptyReply }
    }

    /** Coaching Q&A grounded in the plan summary + prior turns. */
    suspend fun chat(req: ChatRequest): String {
        val messages = buildList {
            add(GlmMessage("system", chatSystem))
            add(GlmMessage("user", "My plan: ${req.planSummary}"))
            add(GlmMessage("assistant", "Got it — I have your plan in mind."))
            req.messages.forEach { add(GlmMessage(it.role, it.content)) }
        }
        val reply = GlmClient.complete(messages = messages, maxTokens = 700)
        return reply.ifBlank { emptyReply }
    }
}

// ---- Public DTOs (client-facing) ----

@Serializable
data class ExplainRequest(val changes: List<String>, val planSummary: String)

@Serializable
data class ChatTurn(val role: String, val content: String)

@Serializable
data class ChatRequest(val messages: List<ChatTurn>, val planSummary: String)

@Serializable
data class AiReply(val text: String)

/** Guards an AI call: requires a Pro entitlement and a configured GLM key. */
fun requireAiAccess(call: ApplicationCall) {
    val user = UserRepository.findById(call.userId())
        ?: throw ApiException(HttpStatusCode.Unauthorized, "Unknown user")
    if (!user.proEntitled) {
        throw ApiException(HttpStatusCode.PaymentRequired, "AI coaching is a Pro feature")
    }
    if (Config.glmApiKey.isNullOrBlank()) {
        throw ApiException(HttpStatusCode.ServiceUnavailable, "AI is not configured")
    }
}
