package com.paceshift.auth

import com.paceshift.Config
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.auth.Authentication
import io.ktor.server.auth.jwt.JWTPrincipal
import io.ktor.server.auth.jwt.jwt

const val JWT_AUTH = "jwt-auth"

/** Installs JWT bearer auth backed by [Jwt.verifier]. */
fun Application.configureSecurity() {
    install(Authentication) {
        jwt(JWT_AUTH) {
            realm = Config.jwtIssuer
            verifier(Jwt.verifier)
            validate { credential ->
                if (credential.payload.subject != null) JWTPrincipal(credential.payload)
                else null
            }
        }
    }
}
