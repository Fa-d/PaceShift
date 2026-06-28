package com.paceshift.db

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.javatime.timestamp

/** Accounts. [passwordHash] is null for users who only sign in via OAuth. */
object Users : UUIDTable("users") {
    val email = varchar("email", 320).uniqueIndex()
    val passwordHash = varchar("password_hash", 100).nullable()
    val displayName = varchar("display_name", 120).nullable()
    val googleSub = varchar("google_sub", 255).nullable().uniqueIndex()
    val appleSub = varchar("apple_sub", 255).nullable().uniqueIndex()
    val proEntitled = bool("pro_entitled").default(false)
    val createdAt = timestamp("created_at")
}

/** One opaque plan-state blob per user (last-writer-wins with a version). */
object SyncStates : UUIDTable("sync_states") {
    val userId = reference("user_id", Users).uniqueIndex()
    val stateJson = text("state_json")
    val version = long("version").default(0)
    val updatedAt = timestamp("updated_at")
}

/** Refresh tokens (hashed) for rotation/revocation. */
object RefreshTokens : UUIDTable("refresh_tokens") {
    val userId = reference("user_id", Users)
    val tokenHash = varchar("token_hash", 100).uniqueIndex()
    val expiresAt = timestamp("expires_at")
    val createdAt = timestamp("created_at")
}
