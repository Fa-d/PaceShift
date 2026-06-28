package com.paceshift

import com.paceshift.ai.aiRoutes
import com.paceshift.auth.authRoutes
import com.paceshift.auth.configureSecurity
import com.paceshift.billing.billingRoutes
import com.paceshift.db.Database
import com.paceshift.plugins.configureSerialization
import com.paceshift.plugins.configureStatusPages
import com.paceshift.sync.syncRoutes
import io.ktor.server.application.Application
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.plugins.calllogging.CallLogging
import io.ktor.server.application.install
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.routing

fun main() {
    Database.init()
    embeddedServer(Netty, port = Config.port, host = "0.0.0.0", module = Application::module)
        .start(wait = true)
}

fun Application.module() {
    install(CallLogging)
    configureSerialization()
    configureStatusPages()
    configureSecurity()

    routing {
        get("/health") { call.respondText("ok") }
        authRoutes()
        syncRoutes()
        billingRoutes()
        aiRoutes()
    }
}
