package com.paceshift.auth

import com.paceshift.db.RefreshTokens
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.deleteWhere
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import org.mindrot.jbcrypt.BCrypt
import java.security.SecureRandom
import java.time.Instant
import java.util.Base64
import java.util.UUID

/** Opaque refresh tokens, stored hashed; supports rotation + revocation. */
object RefreshTokenRepository {
    private val random = SecureRandom()

    /** Returns the raw token (returned to client); only its hash is stored. */
    fun issue(userId: UUID, ttlDays: Long): String {
        val raw = randomToken()
        transaction {
            RefreshTokens.insert {
                it[id] = UUID.randomUUID()
                it[RefreshTokens.userId] = userId
                it[tokenHash] = BCrypt.hashpw(raw, BCrypt.gensalt())
                it[expiresAt] = Instant.now().plusSeconds(ttlDays * 86_400)
                it[createdAt] = Instant.now()
            }
        }
        return raw
    }

    /** Validates a raw refresh token; returns the owning userId or null. */
    fun verify(raw: String): UUID? = transaction {
        val now = Instant.now()
        RefreshTokens.selectAll().forEach { row ->
            if (row[RefreshTokens.expiresAt].isAfter(now) &&
                BCrypt.checkpw(raw, row[RefreshTokens.tokenHash])
            ) {
                return@transaction row[RefreshTokens.userId].value
            }
        }
        null
    }

    fun revoke(raw: String) = transaction {
        val match = RefreshTokens.selectAll()
            .firstOrNull { BCrypt.checkpw(raw, it[RefreshTokens.tokenHash]) }
        if (match != null) {
            val rowId = match[RefreshTokens.id]
            RefreshTokens.deleteWhere { RefreshTokens.id eq rowId }
        }
    }

    private fun randomToken(): String {
        val bytes = ByteArray(32)
        random.nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }
}
