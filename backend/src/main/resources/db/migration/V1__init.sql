CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY,
    email           VARCHAR(320) NOT NULL UNIQUE,
    password_hash   VARCHAR(100),
    display_name    VARCHAR(120),
    google_sub      VARCHAR(255) UNIQUE,
    apple_sub       VARCHAR(255) UNIQUE,
    pro_entitled    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_states (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    state_json  TEXT NOT NULL,
    version     BIGINT NOT NULL DEFAULT 0,
    updated_at  TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(100) NOT NULL UNIQUE,
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
