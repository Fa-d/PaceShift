package com.paceshift.ai

import com.paceshift.Config
import com.paceshift.plugins.ApiException
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.headers
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Shared client for GLM (Zhipu/Z.ai, OpenAI-compatible chat completions). Both AI
 * paths go through here ([AiService] for prose, [GenUiService] for structured UI),
 * so the key, base URL, timeouts, and reasoning toggle are configured in one place.
 *
 * Two things this fixes that bit us before:
 *  - **Explicit [HttpTimeout].** The default CIO request timeout (~15s) killed slow
 *    reasoning models mid-generation; that exception isn't an [ApiException] so it
 *    leaked as a 500. We give reasoning models real headroom.
 *  - **Reasoning disabled by default** ([Config.glmDisableThinking]). GLM 4.5/5.2
 *    are reasoning models: with thinking on they burn the whole token budget on
 *    hidden reasoning and return empty content. Disabling it makes them answer
 *    directly (and far faster).
 */
object GlmClient {
    private val http = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(Json { ignoreUnknownKeys = true })
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 60_000
            connectTimeoutMillis = 15_000
            socketTimeoutMillis = 60_000
        }
    }

    /**
     * Runs a chat completion and returns the raw assistant message content (which
     * may be empty — callers decide how to fall back). [jsonObject] requests a
     * `response_format: json_object` (used by the generative-UI path).
     */
    suspend fun complete(
        messages: List<GlmMessage>,
        maxTokens: Int,
        jsonObject: Boolean = false,
    ): String {
        val key = Config.glmApiKey
            ?: throw ApiException(HttpStatusCode.ServiceUnavailable, "AI is not configured")
        val res = http.post("${Config.glmBaseUrl.trimEnd('/')}/chat/completions") {
            headers { append("Authorization", "Bearer $key") }
            contentType(ContentType.Application.Json)
            setBody(
                GlmRequest(
                    model = Config.glmModel,
                    messages = messages,
                    responseFormat = if (jsonObject) GlmResponseFormat("json_object") else null,
                    temperature = 0.4,
                    maxTokens = maxTokens,
                    thinking = if (Config.glmDisableThinking) GlmThinking("disabled") else null,
                ),
            )
        }
        if (res.status.value !in 200..299) {
            throw ApiException(HttpStatusCode.BadGateway, "AI request failed (${res.status.value})")
        }
        val body: GlmResponse = res.body()
        return body.choices.firstOrNull()?.message?.content?.trim().orEmpty()
    }
}

// ---- GLM wire models (OpenAI-compatible chat completions) ----

@Serializable
data class GlmRequest(
    val model: String,
    val messages: List<GlmMessage>,
    @SerialName("response_format") val responseFormat: GlmResponseFormat? = null,
    val temperature: Double? = null,
    @SerialName("max_tokens") val maxTokens: Int? = null,
    val stream: Boolean = false,
    // Z.ai reasoning toggle ({"type":"disabled"} turns hidden reasoning off).
    val thinking: GlmThinking? = null,
)

@Serializable
data class GlmMessage(val role: String, val content: String)

@Serializable
data class GlmResponseFormat(val type: String)

@Serializable
data class GlmThinking(val type: String)

@Serializable
data class GlmResponse(val choices: List<GlmChoice> = emptyList())

@Serializable
data class GlmChoice(val message: GlmResponseMessage? = null)

@Serializable
data class GlmResponseMessage(val content: String? = null)
