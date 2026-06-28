package com.paceshift

import com.paceshift.auth.AuthResponse
import com.paceshift.auth.RegisterRequest
import com.paceshift.sync.PutSyncRequest
import com.paceshift.sync.PutSyncResponse
import com.paceshift.sync.SyncStateDto
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.bearerAuth
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.server.testing.testApplication
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class SyncTest : IntegrationTest() {

    private suspend fun registerToken(client: HttpClient): String {
        val res = client.post("/auth/register") {
            contentType(ContentType.Application.Json)
            setBody(RegisterRequest("sync_${System.nanoTime()}@example.com", "password123"))
        }
        return res.body<AuthResponse>().accessToken
    }

    @Test
    fun `push then pull round-trips the opaque state`() = testApplication {
        application { module() }
        val client = jsonClient()
        val token = registerToken(client)

        // Empty before first write.
        val empty = client.get("/sync/state") { bearerAuth(token) }
        assertEquals(HttpStatusCode.NoContent, empty.status)

        val put = client.put("/sync/state") {
            bearerAuth(token)
            contentType(ContentType.Application.Json)
            setBody(PutSyncRequest("""{"plan":"v1"}""", baseVersion = 0))
        }
        assertEquals(HttpStatusCode.OK, put.status)
        val putBody: PutSyncResponse = put.body()
        assertEquals(1, putBody.version)
        assertFalse(putBody.conflict)

        val pulled: SyncStateDto =
            client.get("/sync/state") { bearerAuth(token) }.body()
        assertEquals("""{"plan":"v1"}""", pulled.stateJson)
        assertEquals(1, pulled.version)
    }

    @Test
    fun `stale baseVersion is reported as a conflict`() = testApplication {
        application { module() }
        val client = jsonClient()
        val token = registerToken(client)

        client.put("/sync/state") {
            bearerAuth(token)
            contentType(ContentType.Application.Json)
            setBody(PutSyncRequest("""{"v":1}""", baseVersion = 0))
        }
        // Second client write with an outdated baseVersion.
        val conflict: PutSyncResponse = client.put("/sync/state") {
            bearerAuth(token)
            contentType(ContentType.Application.Json)
            setBody(PutSyncRequest("""{"v":2}""", baseVersion = 0))
        }.body()
        assertTrue(conflict.conflict)
        assertEquals(1, conflict.version)
    }
}
