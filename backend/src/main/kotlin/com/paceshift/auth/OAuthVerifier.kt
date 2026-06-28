package com.paceshift.auth

import com.auth0.jwk.JwkProviderBuilder
import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.auth0.jwt.interfaces.RSAKeyProvider
import com.paceshift.Config
import com.paceshift.plugins.ApiException
import io.ktor.http.HttpStatusCode
import java.net.URI
import java.security.interfaces.RSAPublicKey
import java.util.concurrent.TimeUnit

/** Verified identity extracted from a provider ID token. */
data class OAuthIdentity(val subject: String, val email: String, val name: String?)

/**
 * Verifies Google / Apple ID tokens against each provider's published JWKS and
 * checks the issuer + audience (our client IDs). Returns the trusted identity.
 */
object OAuthVerifier {
    private const val GOOGLE_ISSUER = "https://accounts.google.com"
    private const val APPLE_ISSUER = "https://appleid.apple.com"

    private val googleJwks = JwkProviderBuilder(URI("https://www.googleapis.com/oauth2/v3/certs").toURL())
        .cached(10, 24, TimeUnit.HOURS).build()
    private val appleJwks = JwkProviderBuilder(URI("https://appleid.apple.com/auth/keys").toURL())
        .cached(10, 24, TimeUnit.HOURS).build()

    fun verify(provider: OAuthProvider, idToken: String): OAuthIdentity {
        val issuer = if (provider == OAuthProvider.GOOGLE) GOOGLE_ISSUER else APPLE_ISSUER
        val audiences =
            if (provider == OAuthProvider.GOOGLE) Config.googleClientIds else Config.appleClientIds
        val jwks = if (provider == OAuthProvider.GOOGLE) googleJwks else appleJwks

        val decoded = try {
            val unverified = JWT.decode(idToken)
            val algorithm = Algorithm.RSA256(object : RSAKeyProvider {
                override fun getPublicKeyById(keyId: String) =
                    jwks.get(keyId).publicKey as RSAPublicKey
                override fun getPrivateKey() = null
                override fun getPrivateKeyId() = null
            })
            JWT.require(algorithm).withIssuer(issuer).build().verify(unverified)
        } catch (e: Exception) {
            throw ApiException(HttpStatusCode.Unauthorized, "Invalid ID token: ${e.message}")
        }

        if (audiences.isNotEmpty() && decoded.audience.none { it in audiences }) {
            throw ApiException(HttpStatusCode.Unauthorized, "Token audience mismatch")
        }
        val email = decoded.getClaim("email").asString()
            ?: throw ApiException(HttpStatusCode.BadRequest, "ID token has no email")
        val name = decoded.getClaim("name").asString()
        return OAuthIdentity(decoded.subject, email, name)
    }
}
