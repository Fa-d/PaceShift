package com.paceshift

import com.paceshift.auth.AuthResponse
import com.paceshift.auth.LoginRequest
import com.paceshift.auth.RegisterRequest
import io.ktor.client.call.body
import io.ktor.client.request.bearerAuth
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.server.testing.testApplication
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AuthTest : IntegrationTest() {

    private fun uniqueEmail() = "user_${System.nanoTime()}@example.com"

    @Test
    fun `register then access profile with the token`() = testApplication {
        application { module() }
        val client = jsonClient()
        val email = uniqueEmail()

        val reg = client.post("/auth/register") {
            contentType(ContentType.Application.Json)
            setBody(RegisterRequest(email, "password123", "Pat Runner"))
        }
        assertEquals(HttpStatusCode.Created, reg.status)
        val auth: AuthResponse = reg.body()
        assertTrue(auth.accessToken.isNotBlank())
        assertEquals(email, auth.user.email)

        val profile = client.get("/profile") { bearerAuth(auth.accessToken) }
        assertEquals(HttpStatusCode.OK, profile.status)
    }

    @Test
    fun `login fails with a wrong password`() = testApplication {
        application { module() }
        val client = jsonClient()
        val email = uniqueEmail()

        client.post("/auth/register") {
            contentType(ContentType.Application.Json)
            setBody(RegisterRequest(email, "password123"))
        }
        val bad = client.post("/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(LoginRequest(email, "wrongpass"))
        }
        assertEquals(HttpStatusCode.Unauthorized, bad.status)
    }

    @Test
    fun `profile requires a token`() = testApplication {
        application { module() }
        val res = jsonClient().get("/profile")
        assertEquals(HttpStatusCode.Unauthorized, res.status)
    }
}
