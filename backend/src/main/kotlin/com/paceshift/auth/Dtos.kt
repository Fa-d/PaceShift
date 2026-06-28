package com.paceshift.auth

import kotlinx.serialization.Serializable

@Serializable
data class RegisterRequest(
    val email: String,
    val password: String,
    val displayName: String? = null,
)

@Serializable
data class LoginRequest(val email: String, val password: String)

@Serializable
data class RefreshRequest(val refreshToken: String)

/** OAuth sign-in: the provider's ID token from the mobile SDK. */
@Serializable
data class OAuthRequest(val idToken: String)

@Serializable
data class UserDto(
    val id: String,
    val email: String,
    val displayName: String? = null,
    val proEntitled: Boolean = false,
)

@Serializable
data class AuthResponse(
    val accessToken: String,
    val refreshToken: String,
    val user: UserDto,
)
