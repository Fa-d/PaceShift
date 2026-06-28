package com.paceshift.auth

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.paceshift.Config
import java.util.Date

/** Issues and configures our own access JWTs. */
object Jwt {
    private val algorithm = Algorithm.HMAC256(Config.jwtSecret)

    val verifier = JWT.require(algorithm)
        .withIssuer(Config.jwtIssuer)
        .withAudience(Config.jwtAudience)
        .build()

    fun accessToken(userId: String, email: String): String {
        val now = System.currentTimeMillis()
        return JWT.create()
            .withIssuer(Config.jwtIssuer)
            .withAudience(Config.jwtAudience)
            .withSubject(userId)
            .withClaim("email", email)
            .withIssuedAt(Date(now))
            .withExpiresAt(Date(now + Config.accessTokenMinutes * 60_000))
            .sign(algorithm)
    }
}
