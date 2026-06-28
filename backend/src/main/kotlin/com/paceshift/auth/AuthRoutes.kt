package com.paceshift.auth

import io.ktor.http.HttpStatusCode
import io.ktor.server.auth.authenticate
import io.ktor.server.auth.jwt.JWTPrincipal
import io.ktor.server.auth.principal
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.delete
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.route
import java.util.UUID

fun Route.authRoutes() {
    route("/auth") {
        post("/register") {
            call.respond(HttpStatusCode.Created, AuthService.register(call.receive()))
        }
        post("/login") {
            call.respond(AuthService.login(call.receive()))
        }
        post("/refresh") {
            call.respond(AuthService.refresh(call.receive()))
        }
        post("/oauth/google") {
            call.respond(AuthService.oauth(OAuthProvider.GOOGLE, call.receive()))
        }
        post("/oauth/apple") {
            call.respond(AuthService.oauth(OAuthProvider.APPLE, call.receive()))
        }
    }

    authenticate(JWT_AUTH) {
        get("/profile") {
            val userId = call.userId()
            call.respond(AuthService.me(userId))
        }
        // Account deletion (App Store / Play Store requirement). Cascades to the
        // user's sync state and refresh tokens via ON DELETE CASCADE.
        delete("/profile") {
            AuthService.deleteAccount(call.userId())
            call.respond(HttpStatusCode.NoContent)
        }
    }
}

/** The authenticated user's id, parsed from the JWT subject. */
fun io.ktor.server.application.ApplicationCall.userId(): UUID =
    UUID.fromString(principal<JWTPrincipal>()!!.subject!!)
