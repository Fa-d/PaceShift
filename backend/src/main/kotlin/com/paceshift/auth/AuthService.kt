package com.paceshift.auth

import com.paceshift.Config
import com.paceshift.plugins.ApiException
import io.ktor.http.HttpStatusCode
import org.mindrot.jbcrypt.BCrypt
import java.util.UUID

/** Orchestrates registration, login, OAuth, and token refresh. */
object AuthService {
    private val emailRegex = Regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")

    fun register(req: RegisterRequest): AuthResponse {
        val email = req.email.trim().lowercase()
        if (!emailRegex.matches(email)) {
            throw ApiException(HttpStatusCode.BadRequest, "Invalid email")
        }
        if (req.password.length < 8) {
            throw ApiException(HttpStatusCode.BadRequest, "Password must be ≥ 8 characters")
        }
        if (UserRepository.findByEmail(email) != null) {
            throw ApiException(HttpStatusCode.Conflict, "Email already registered")
        }
        val hash = BCrypt.hashpw(req.password, BCrypt.gensalt())
        val user = UserRepository.create(email, hash, req.displayName)
        return tokensFor(user)
    }

    fun login(req: LoginRequest): AuthResponse {
        val user = UserRepository.findByEmail(req.email.trim().lowercase())
            ?: throw ApiException(HttpStatusCode.Unauthorized, "Invalid credentials")
        val hash = user.passwordHash
            ?: throw ApiException(HttpStatusCode.Unauthorized, "Use social sign-in for this account")
        if (!BCrypt.checkpw(req.password, hash)) {
            throw ApiException(HttpStatusCode.Unauthorized, "Invalid credentials")
        }
        return tokensFor(user)
    }

    fun oauth(provider: OAuthProvider, req: OAuthRequest): AuthResponse {
        val identity = OAuthVerifier.verify(provider, req.idToken)
        val user = UserRepository.upsertOAuth(
            provider, identity.subject, identity.email, identity.name,
        )
        return tokensFor(user)
    }

    fun refresh(req: RefreshRequest): AuthResponse {
        val userId = RefreshTokenRepository.verify(req.refreshToken)
            ?: throw ApiException(HttpStatusCode.Unauthorized, "Invalid refresh token")
        val user = UserRepository.findById(userId)
            ?: throw ApiException(HttpStatusCode.Unauthorized, "User no longer exists")
        // Rotate: revoke the presented token, issue a fresh pair.
        RefreshTokenRepository.revoke(req.refreshToken)
        return tokensFor(user)
    }

    fun me(userId: UUID): UserDto =
        (UserRepository.findById(userId)
            ?: throw ApiException(HttpStatusCode.NotFound, "User not found")).toDto()

    fun deleteAccount(userId: UUID) = UserRepository.delete(userId)

    private fun tokensFor(user: UserRecord): AuthResponse {
        val access = Jwt.accessToken(user.id.toString(), user.email)
        val refresh = RefreshTokenRepository.issue(user.id, Config.refreshTokenDays)
        return AuthResponse(access, refresh, user.toDto())
    }
}
