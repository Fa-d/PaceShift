package com.paceshift

import com.paceshift.db.Database
import io.ktor.client.HttpClient
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.testing.ApplicationTestBuilder
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.BeforeAll
import org.testcontainers.containers.PostgreSQLContainer

/**
 * Base for backend tests. Connects to a Postgres provided via TEST_DATABASE_URL
 * (e.g. the docker-compose `db` service) when set; otherwise spins up a
 * throwaway Postgres via Testcontainers. Runs Flyway + connects Exposed once.
 */
abstract class IntegrationTest {
    companion object {
        @Volatile
        private var started = false

        @JvmStatic
        @BeforeAll
        fun setup() {
            if (started) return
            synchronized(this) {
                if (started) return
                val externalUrl = System.getenv("TEST_DATABASE_URL")
                if (externalUrl != null) {
                    Database.init(
                        externalUrl,
                        System.getenv("TEST_DATABASE_USER") ?: "paceshift",
                        System.getenv("TEST_DATABASE_PASSWORD") ?: "paceshift",
                    )
                } else {
                    val pg = PostgreSQLContainer("postgres:16-alpine")
                        .withDatabaseName("paceshift")
                        .withUsername("paceshift")
                        .withPassword("paceshift")
                    pg.start()
                    Database.init(pg.jdbcUrl, pg.username, pg.password)
                }
                started = true
            }
        }
    }
}

/** A JSON-aware test client. */
fun ApplicationTestBuilder.jsonClient(): HttpClient = createClient {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true })
    }
}
