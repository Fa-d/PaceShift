package com.paceshift.plugins

import io.ktor.http.HttpStatusCode
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.statuspages.StatusPages
import io.ktor.server.response.respond
import kotlinx.serialization.Serializable

/** Thrown by services to return a specific HTTP status with a message. */
class ApiException(val status: HttpStatusCode, override val message: String) :
    RuntimeException(message)

@Serializable
data class ErrorResponse(val error: String)

fun Application.configureStatusPages() {
    install(StatusPages) {
        exception<ApiException> { call, cause ->
            call.respond(cause.status, ErrorResponse(cause.message))
        }
        exception<Throwable> { call, cause ->
            call.respond(
                HttpStatusCode.InternalServerError,
                ErrorResponse(cause.message ?: "Internal error"),
            )
        }
    }
}
