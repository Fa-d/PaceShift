package com.paceshift

/**
 * Environment-driven configuration. All secrets come from env vars so nothing
 * sensitive is committed. Sensible local defaults are provided for development
 * via docker-compose.
 */
object Config {
    val port: Int = System.getenv("PORT")?.toIntOrNull() ?: 8080

    val dbUrl: String = System.getenv("DATABASE_URL")
        ?: "jdbc:postgresql://localhost:5432/paceshift"
    val dbUser: String = System.getenv("DATABASE_USER") ?: "paceshift"
    val dbPassword: String = System.getenv("DATABASE_PASSWORD") ?: "paceshift"

    // JWT signing. Override JWT_SECRET in production.
    val jwtSecret: String = System.getenv("JWT_SECRET") ?: "dev-secret-change-me"
    val jwtIssuer: String = System.getenv("JWT_ISSUER") ?: "paceshift"
    val jwtAudience: String = System.getenv("JWT_AUDIENCE") ?: "paceshift-app"
    val accessTokenMinutes: Long =
        System.getenv("ACCESS_TOKEN_MINUTES")?.toLongOrNull() ?: 60
    val refreshTokenDays: Long =
        System.getenv("REFRESH_TOKEN_DAYS")?.toLongOrNull() ?: 30

    // OAuth client IDs used to validate provider ID tokens (set in production).
    val googleClientIds: List<String> =
        (System.getenv("GOOGLE_CLIENT_IDS") ?: "").split(",").filter { it.isNotBlank() }
    val appleClientIds: List<String> =
        (System.getenv("APPLE_CLIENT_IDS") ?: "com.paceshift.app")
            .split(",").filter { it.isNotBlank() }

    // RevenueCat webhook auth header (Bearer) + entitlement id.
    val revenueCatAuthToken: String? = System.getenv("REVENUECAT_AUTH_TOKEN")
    val proEntitlementId: String = System.getenv("PRO_ENTITLEMENT_ID") ?: "pro"

    // Anthropic (AI proxy) — Phase 10. Default to the most capable Claude model.
    val anthropicApiKey: String? = System.getenv("ANTHROPIC_API_KEY")
    val anthropicModel: String =
        System.getenv("ANTHROPIC_MODEL") ?: "claude-opus-4-8"
    val anthropicVersion: String = "2023-06-01"

    // GLM 5.2 (generative-UI proxy) — Phase 12. OpenAI-compatible chat endpoint.
    // Base URL defaults to Z.ai; override GLM_BASE_URL / GLM_MODEL for another
    // provider (Together "zai-org/GLM-5.2", AIMLAPI "zhipu/glm-5-2", OpenRouter…).
    val glmApiKey: String? = System.getenv("GLM_API_KEY")
    val glmBaseUrl: String =
        System.getenv("GLM_BASE_URL") ?: "https://api.z.ai/api/paas/v4"
    val glmModel: String = System.getenv("GLM_MODEL") ?: "glm-5.2"

    // GLM 4.5/5.2 are reasoning models. With reasoning ON they spend the whole
    // token budget on hidden reasoning and return empty content (and are slow
    // enough to trip the HTTP timeout). Disabled by default; set
    // GLM_DISABLE_THINKING=false only on a model where reasoning is wanted.
    val glmDisableThinking: Boolean =
        System.getenv("GLM_DISABLE_THINKING")?.toBoolean() ?: true
}
