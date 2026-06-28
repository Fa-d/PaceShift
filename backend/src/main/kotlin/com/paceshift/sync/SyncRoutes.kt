package com.paceshift.sync

import com.paceshift.auth.JWT_AUTH
import com.paceshift.auth.userId
import com.paceshift.db.SyncStates
import io.ktor.http.HttpStatusCode
import io.ktor.server.auth.authenticate
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.put
import io.ktor.server.routing.route
import kotlinx.serialization.Serializable
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.update
import java.time.Instant
import java.util.UUID

/** The device's full plan/runs/settings state as opaque JSON, plus a version. */
@Serializable
data class SyncStateDto(val stateJson: String, val version: Long, val updatedAt: Long)

@Serializable
data class PutSyncRequest(val stateJson: String, val baseVersion: Long)

@Serializable
data class PutSyncResponse(val version: Long, val conflict: Boolean, val server: SyncStateDto?)

fun Route.syncRoutes() {
    authenticate(JWT_AUTH) {
        route("/sync/state") {
            get {
                val state = SyncRepository.get(call.userId())
                if (state == null) call.respond(HttpStatusCode.NoContent)
                else call.respond(state)
            }
            put {
                val req = call.receive<PutSyncRequest>()
                call.respond(SyncRepository.put(call.userId(), req))
            }
        }
    }
}

/** Stores one opaque state blob per user with optimistic-concurrency versioning. */
object SyncRepository {
    fun get(userId: UUID): SyncStateDto? = transaction {
        SyncStates.selectAll().where { SyncStates.userId eq userId }.firstOrNull()?.let {
            SyncStateDto(
                it[SyncStates.stateJson],
                it[SyncStates.version],
                it[SyncStates.updatedAt].toEpochMilli(),
            )
        }
    }

    /**
     * Last-writer-wins with conflict detection: if the client's [PutSyncRequest.baseVersion]
     * is behind the stored version, the write is rejected and the server copy returned.
     */
    fun put(userId: UUID, req: PutSyncRequest): PutSyncResponse = transaction {
        val existing = SyncStates.selectAll().where { SyncStates.userId eq userId }.firstOrNull()
        if (existing == null) {
            val version = 1L
            SyncStates.insert {
                it[id] = UUID.randomUUID()
                it[SyncStates.userId] = userId
                it[stateJson] = req.stateJson
                it[SyncStates.version] = version
                it[updatedAt] = Instant.now()
            }
            return@transaction PutSyncResponse(version, conflict = false, server = null)
        }

        val current = existing[SyncStates.version]
        if (req.baseVersion < current) {
            return@transaction PutSyncResponse(
                current,
                conflict = true,
                server = SyncStateDto(
                    existing[SyncStates.stateJson],
                    current,
                    existing[SyncStates.updatedAt].toEpochMilli(),
                ),
            )
        }
        val next = current + 1
        SyncStates.update({ SyncStates.userId eq userId }) {
            it[stateJson] = req.stateJson
            it[version] = next
            it[updatedAt] = Instant.now()
        }
        PutSyncResponse(next, conflict = false, server = null)
    }
}
