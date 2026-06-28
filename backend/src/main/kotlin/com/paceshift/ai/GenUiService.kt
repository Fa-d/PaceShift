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
 * Generative-UI proxy (Phase 12 — commercialization). Instead of returning prose
 * like [AiService], this asks **GLM 5.2** (Zhipu/Z.ai, OpenAI-compatible) to
 * compose a **structured UI spec** — a flat, allow-listed list of [UiBlock]s that
 * the Flutter client renders natively (genui catalog).
 *
 * The model only **arranges grounded facts** (the engine's RescheduleOutcome
 * changelog + the plan summary). The engine itself stays pure + client-side; the
 * server never runs it. Output is parsed leniently and filtered to the
 * allow-listed block types, so a malformed/creative response degrades to a clean,
 * safe subset rather than reaching the renderer raw.
 *
 * This is intentionally **separate** from the Claude path ([AiService]): the
 * existing `/ai/explain` + `/ai/chat` endpoints are unchanged.
 */
object GenUiService {
    private val http = HttpClient(CIO) {
        install(ContentNegotiation) {
            json(Json { ignoreUnknownKeys = true })
        }
    }

    /** Lenient parser for the model's JSON payload (it may add stray fields). */
    private val lenient = Json { ignoreUnknownKeys = true; isLenient = true }

    /** The only block types the client catalog can render. Enforced server-side. */
    private val allowedTypes = setOf(
        "section", "text", "metric", "status_chip", "shift_banner",
        "run_card", "empty_state", "action_button",
    )

    private val systemPrompt = """
        You are PaceShift's running coach. You do NOT write prose paragraphs — you
        compose a small native UI by returning a JSON object that the app renders.

        Return ONLY a JSON object of this exact shape (no markdown, no commentary):
        {"blocks": [ <block>, ... ]}

        Each <block> has a "type" and a subset of these fields. Use ONLY these types:
        - {"type":"section","title": string}                      // a heading
        - {"type":"text","body": string}                          // 1-2 short sentences
        - {"type":"metric","value": string,"label": string,"tone": tone}
        - {"type":"status_chip","label": string,"tone": tone}
        - {"type":"shift_banner","text": string}                  // "moved X -> Y" notice
        - {"type":"run_card","runId": int,"title": string,"subtitle": string,"status": status}
        - {"type":"empty_state","title": string,"message": string}
        - {"type":"action_button","label": string,"action": action,"style": style,"confirm": bool}

        tone   ∈ "positive" | "caution" | "critical" | "neutral"
        status ∈ "completed" | "shifted" | "reduced" | "missed" | "planned"
        action ∈ "mark_done" | "could_not_run" | "open_run" | "ask"  // set runId for the run it acts on
        style  ∈ "filled" | "outlined" | "text"

        Action meanings (the app executes these natively):
        - "open_run": open the run's detail screen (needs runId).
        - "mark_done": mark that planned run completed (needs runId).
        - "could_not_run": tell the engine the runner can't do that run; it safely
          reshuffles the plan (needs runId).
        - "ask": ask a follow-up; put the question text in "label".

        Rules:
        - Use ONLY the facts provided. Never invent runs, dates, distances, or numbers.
        - Set runId on run_card and on action_buttons that act on a specific run.
        - Keep it focused: at most 8 blocks. Lead with the most important thing.
        - Set "confirm": true on plan-changing actions (mark_done, could_not_run).
        - Be warm and reassuring: the plan adapts safely and protects the race date.
        - No medical advice. If asked, add a text block suggesting a professional.
    """.trimIndent()

    /** Composes a UI spec from grounded context (+ optional free-form question). */
    suspend fun compose(req: GenUiRequest): GenUiSpec {
        val userTurn = buildString {
            appendLine("Plan summary: ${req.planSummary}")
            if (req.changes.isNotEmpty()) {
                appendLine()
                appendLine("Recent engine changes (facts you may arrange):")
                req.changes.forEach { appendLine("- $it") }
            }
            if (!req.question.isNullOrBlank()) {
                appendLine()
                appendLine("The runner asks: ${req.question}")
            }
            appendLine()
            append("Compose a UI that answers helpfully, grounded in the facts above.")
        }
        val raw = callGlm(systemPrompt, userTurn)
        return parseSpec(raw)
    }

    private suspend fun callGlm(system: String, user: String): String {
        val key = Config.glmApiKey
            ?: throw ApiException(HttpStatusCode.ServiceUnavailable, "Generative UI is not configured")
        val res = http.post("${Config.glmBaseUrl.trimEnd('/')}/chat/completions") {
            headers { append("Authorization", "Bearer $key") }
            contentType(ContentType.Application.Json)
            setBody(
                GlmRequest(
                    model = Config.glmModel,
                    messages = listOf(
                        GlmMessage("system", system),
                        GlmMessage("user", user),
                    ),
                    responseFormat = GlmResponseFormat("json_object"),
                    temperature = 0.4,
                    // GLM 4.5/5.2 are reasoning models: hidden reasoning tokens are
                    // billed against max_tokens before the JSON, so leave headroom.
                    maxTokens = 2000,
                ),
            )
        }
        if (!res.status.isSuccess()) {
            throw ApiException(HttpStatusCode.BadGateway, "Generative UI request failed (${res.status.value})")
        }
        val body: GlmResponse = res.body()
        return body.choices.firstOrNull()?.message?.content?.trim().orEmpty()
    }

    /**
     * Parses the model's JSON and keeps only allow-listed blocks. Any failure
     * (empty, fenced, malformed, unknown types) degrades to a single safe text
     * block instead of surfacing raw model output to the renderer.
     */
    internal fun parseSpec(raw: String): GenUiSpec {
        val json = stripFences(raw)
        val spec = runCatching { lenient.decodeFromString<GenUiSpec>(json) }.getOrNull()
        val blocks = spec?.blocks
            ?.filter { it.type in allowedTypes }
            ?.take(8)
            ?: emptyList()
        return if (blocks.isEmpty()) fallbackSpec else GenUiSpec(blocks)
    }

    /** Strips ```json ... ``` fences the model sometimes wraps JSON in. */
    private fun stripFences(s: String): String {
        val t = s.trim()
        if (!t.startsWith("```")) return t
        return t.removePrefix("```json").removePrefix("```")
            .removeSuffix("```").trim()
    }

    private val fallbackSpec = GenUiSpec(
        listOf(UiBlock(type = "text", body = "I couldn't compose a view just now — please try again.")),
    )
}

private fun HttpStatusCode.isSuccess() = value in 200..299

/**
 * Guards the generative-UI call: requires a Pro entitlement and a configured GLM
 * key. Mirrors [requireAiAccess] but checks the GLM provider instead of Anthropic,
 * so the two AI paths can be configured independently.
 */
fun requireGenUiAccess(call: ApplicationCall) {
    val user = UserRepository.findById(call.userId())
        ?: throw ApiException(HttpStatusCode.Unauthorized, "Unknown user")
    if (!user.proEntitled) {
        throw ApiException(HttpStatusCode.PaymentRequired, "Generative-UI coaching is a Pro feature")
    }
    if (Config.glmApiKey.isNullOrBlank()) {
        throw ApiException(HttpStatusCode.ServiceUnavailable, "Generative UI is not configured")
    }
}

// ---- Public DTOs (client-facing) ----

@Serializable
data class GenUiRequest(
    val planSummary: String,
    val changes: List<String> = emptyList(),
    val question: String? = null,
)

/** A composed surface: a flat, bounded list of catalog blocks. */
@Serializable
data class GenUiSpec(val blocks: List<UiBlock> = emptyList())

/**
 * One catalog block. Fields are a permissive superset across all block types
 * (kept flat so the wire schema is non-recursive and trivially serializable); the
 * client renderer reads only the fields relevant to [type].
 */
@Serializable
data class UiBlock(
    val type: String,
    val title: String? = null,
    val subtitle: String? = null,
    val label: String? = null,
    val value: String? = null,
    val body: String? = null,
    val message: String? = null,
    val text: String? = null,
    val tone: String? = null,
    val status: String? = null,
    val runId: Int? = null,
    val action: String? = null,
    val style: String? = null,
    val confirm: Boolean? = null,
)

// ---- GLM wire models (OpenAI-compatible chat completions) ----

@Serializable
private data class GlmRequest(
    val model: String,
    val messages: List<GlmMessage>,
    @SerialName("response_format") val responseFormat: GlmResponseFormat? = null,
    val temperature: Double? = null,
    @SerialName("max_tokens") val maxTokens: Int? = null,
    val stream: Boolean = false,
)

@Serializable
private data class GlmMessage(val role: String, val content: String)

@Serializable
private data class GlmResponseFormat(val type: String)

@Serializable
private data class GlmResponse(val choices: List<GlmChoice> = emptyList())

@Serializable
private data class GlmChoice(val message: GlmResponseMessage? = null)

@Serializable
private data class GlmResponseMessage(val content: String? = null)
