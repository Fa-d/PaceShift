package com.paceshift.auth

import com.paceshift.db.Users
import org.jetbrains.exposed.sql.ResultRow
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.and
import org.jetbrains.exposed.sql.deleteWhere
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.update
import java.time.Instant
import java.util.UUID

/** A user row mapped out of Exposed. */
data class UserRecord(
    val id: UUID,
    val email: String,
    val passwordHash: String?,
    val displayName: String?,
    val proEntitled: Boolean,
) {
    fun toDto() = UserDto(id.toString(), email, displayName, proEntitled)
}

object UserRepository {
    private fun ResultRow.toUser() = UserRecord(
        id = this[Users.id].value,
        email = this[Users.email],
        passwordHash = this[Users.passwordHash],
        displayName = this[Users.displayName],
        proEntitled = this[Users.proEntitled],
    )

    fun findByEmail(email: String): UserRecord? = transaction {
        Users.selectAll().where { Users.email eq email.lowercase() }
            .firstOrNull()?.toUser()
    }

    fun findById(id: UUID): UserRecord? = transaction {
        Users.selectAll().where { Users.id eq id }.firstOrNull()?.toUser()
    }

    fun create(
        email: String,
        passwordHash: String?,
        displayName: String?,
        googleSub: String? = null,
        appleSub: String? = null,
    ): UserRecord = transaction {
        val newId = UUID.randomUUID()
        Users.insert {
            it[Users.id] = newId
            it[Users.email] = email.lowercase()
            it[Users.passwordHash] = passwordHash
            it[Users.displayName] = displayName
            it[Users.googleSub] = googleSub
            it[Users.appleSub] = appleSub
            it[createdAt] = Instant.now()
        }
        UserRecord(newId, email.lowercase(), passwordHash, displayName, false)
    }

    /** Finds a user by provider subject, creating/linking by email if needed. */
    fun upsertOAuth(
        provider: OAuthProvider,
        subject: String,
        email: String,
        displayName: String?,
    ): UserRecord = transaction {
        val subCol = if (provider == OAuthProvider.GOOGLE) Users.googleSub else Users.appleSub
        val bySub = Users.selectAll().where { subCol eq subject }.firstOrNull()?.toUser()
        if (bySub != null) return@transaction bySub

        val byEmail = Users.selectAll().where { Users.email eq email.lowercase() }
            .firstOrNull()?.toUser()
        if (byEmail != null) {
            Users.update({ Users.id eq byEmail.id }) {
                if (provider == OAuthProvider.GOOGLE) it[googleSub] = subject
                else it[appleSub] = subject
            }
            return@transaction byEmail
        }
        create(
            email = email,
            passwordHash = null,
            displayName = displayName,
            googleSub = if (provider == OAuthProvider.GOOGLE) subject else null,
            appleSub = if (provider == OAuthProvider.APPLE) subject else null,
        )
    }

    fun setProEntitled(userId: UUID, entitled: Boolean) = transaction {
        Users.update({ Users.id eq userId }) { it[proEntitled] = entitled }
    }

    /** Deletes the user and (via ON DELETE CASCADE) their sync state + tokens. */
    fun delete(userId: UUID) = transaction {
        Users.deleteWhere { Users.id eq userId }
    }

    fun setProEntitledByEmail(email: String, entitled: Boolean): Boolean = transaction {
        Users.update({ Users.email eq email.lowercase() }) {
            it[proEntitled] = entitled
        } > 0
    }
}

enum class OAuthProvider { GOOGLE, APPLE }
