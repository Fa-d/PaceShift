-- DEV SEED — a Pro-enabled test account for local development & QA.
--
--   email:     demo+pro@paceshift.app
--   password:  DemoPro!2026
--   display:   Pro Demo
--
-- Idempotent: re-running (e.g. flyway repair / re-apply) keeps the row stable
-- and re-asserts pro_entitled = true and the known password.
--
-- ⚠️ WARNING: known credentials + pro_entitled = true. This is dev/QA-only.
-- Remove this migration (and any seeded row) before deploying to production,
-- or gate it behind a dev-only Flyway location.
INSERT INTO users (id, email, password_hash, display_name, pro_entitled, created_at)
VALUES (
    '1aa52526-9a58-4e91-ad8f-4ac548c741ff',
    'demo+pro@paceshift.app',
    '$2a$10$5RqVMrdyIW2VxIuBewpeoebiyhsm5hbeeLeh5jKEpwG8NzNdJqrta',
    'Pro Demo',
    TRUE,
    NOW()
)
ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    display_name  = EXCLUDED.display_name,
    pro_entitled  = TRUE;
