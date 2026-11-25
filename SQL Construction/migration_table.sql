CREATE TABLE IF NOT EXISTS general.gl_data_migration_log (
    log_id INTEGER GENERATED ALWAYS AS IDENTITY,
    migration_ts TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,
    source_table VARCHAR(100),
    organisation VARCHAR(100),
    gl_year VARCHAR(10),
    source_rows BIGINT,
    target_rows BIGINT,
    source_balance NUMERIC,
    target_balance NUMERIC,
    success BOOLEAN,
    error_message TEXT
);
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA general TO Postgres_admin;

SELECT *
FROM general.gl_data_migration_log;