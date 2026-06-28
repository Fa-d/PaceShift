package com.paceshift.db

import com.paceshift.Config
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import org.flywaydb.core.Flyway
import org.jetbrains.exposed.sql.Database as ExposedDatabase
import javax.sql.DataSource

/** Connection pool, Flyway migrations, and the Exposed [ExposedDatabase] handle. */
object Database {
    lateinit var dataSource: DataSource
        private set

    fun init(
        url: String = Config.dbUrl,
        user: String = Config.dbUser,
        password: String = Config.dbPassword,
    ) {
        val ds = HikariDataSource(HikariConfig().apply {
            jdbcUrl = url
            username = user
            this.password = password
            driverClassName = "org.postgresql.Driver"
            maximumPoolSize = 10
        })
        dataSource = ds

        Flyway.configure()
            .dataSource(ds)
            .locations("classpath:db/migration")
            .load()
            .migrate()

        ExposedDatabase.connect(ds)
    }
}
