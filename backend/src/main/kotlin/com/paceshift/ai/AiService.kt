package com.paceshift.ai

import com.paceshift.Config
import com.paceshift.auth.UserRepository
import com.paceshift.auth.userId
import com.paceshift.plugins.ApiException
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.headers
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.ApplicationCall
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Thin server-side proxy to the Anthropic Messages API. The Anthropic key never
 * leaves the server. Responses are **grounded** in the engine's actual
 * RescheduleOutcome changelog + the user's plan summary — Claude phrases the
 * facts, it does not invent them.
 */
object AiService {
    private val http = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(Json { ignoreUnknownKeys = true })
        }
    }

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
        return callAnthropic(explainSystem, listOf(AnthropicMessage("user", user)), 400)
    }

    /** Coaching Q&A grounded in the plan summary + prior turns. */
    suspend fun chat(req: ChatRequest): String {
        val messages = buildList {
            add(AnthropicMessage("user", "My plan: ${req.planSummary}"))
            add(AnthropicMessage("assistant", "Got it — I have your plan in mind."))
            req.messages.forEach { add(AnthropicMessage(it.role, it.content)) }
        }
        return callAnthropic(chatSystem, messages, 600)
    }

    private suspend fun callAnthropic(
        system: String,
        messages: List<AnthropicMessage>,
        maxTokens: Int,
    ): String {
        val key = Config.anthropicApiKey
            ?: throw ApiException(HttpStatusCode.ServiceUnavailable, "AI is not configured")
        val res = http.post("https://api.anthropic.com/v1/messages") {
            headers {
                append("x-api-key", key)
                append("anthropic-version", Config.anthropicVersion)
            }
            contentType(ContentType.Application.Json)
            setBody(
                AnthropicRequest(
                    model = Config.anthropicModel,
                    maxTokens = maxTokens,
                    system = system,
                    messages = messages,
                ),
            )
        }
        if (!res.status.isSuccess()) {
            throw ApiException(HttpStatusCode.BadGateway, "AI request failed (${res.status.value})")
        }
        val body: AnthropicResponse = res.body()
        return body.content.firstOrNull { it.type == "text" }?.text?.trim()
            ?: "I couldn't generate a response just now."
    }
}

private fun HttpStatusCode.isSuccess() = value in 200..299

// ---- Public DTOs (client-facing) ----

@Serializable
data class ExplainRequest(val changes: List<String>, val planSummary: String)

@Serializable
data class ChatTurn(val role: String, val content: String)

@Serializable
data class ChatRequest(val messages: List<ChatTurn>, val planSummary: String)

@Serializable
data class AiReply(val text: String)

// ---- Anthropic wire models ----

@Serializable
private data class AnthropicRequest(
    val model: String,
    @SerialName("max_tokens") val maxTokens: Int,
    val system: String,
    val messages: List<AnthropicMessage>,
)

@Serializable
private data class AnthropicMessage(val role: String, val content: String)

@Serializable
private data class AnthropicResponse(val content: List<AnthropicContent> = emptyList())

@Serializable
private data class AnthropicContent(val type: String, val text: String? = null)

/** Guards an AI call: requires a Pro entitlement and a configured API key. */
fun requireAiAccess(call: ApplicationCall) {
    val user = UserRepository.findById(call.userId())
        ?: throw ApiException(HttpStatusCode.Unauthorized, "Unknown user")
    if (!user.proEntitled) {
        throw ApiException(HttpStatusCode.PaymentRequired, "AI coaching is a Pro feature")
    }
    if (Config.anthropicApiKey.isNullOrBlank()) {
        throw ApiException(HttpStatusCode.ServiceUnavailable, "AI is not configured")
    }
}
