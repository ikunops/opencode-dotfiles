---
name: postgresql
description: PostgreSQL coding standards, query optimization, indexing, partitioning, migrations, security, replication, and monitoring best practices.
---

# PostgreSQL Skill

**Roadmap Alignment:** [roadmap.sh/postgresql-dba](https://roadmap.sh/postgresql-dba)
**Reference:** [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)

## When to Use This Skill

- Writing and reviewing SQL queries and schema designs
- Creating database migrations (standalone or framework-integrated)
- Performance tuning and index optimization
- Partitioning, window functions, and advanced query patterns
- Database security, access control, and Row-Level Security
- Connection pooling, transaction management, and locking
- Replication, backup/restore, and monitoring

## Core Standards

### 1. Query Best Practices

- **Parameterized Queries:** Always use prepared statements with placeholders (`$1`, `$2`, ...). Never concatenate user input into SQL.
- **Avoid N+1 Queries:** Fetch related data in one query via `JOIN` or CTEs.
- **Explicit Column Selection:** `SELECT col1, col2` instead of `SELECT *`.
- **Case Sensitivity:** Unquoted identifiers are folded to lowercase. Use lowercase snake_case consistently; only quote when needed.
- **CTEs over derived tables** for readability on complex multi-step queries.

### 2. Indexing Conventions

- **Primary Keys:** Always define one. Use `BIGSERIAL` / `GENERATED ALWAYS AS IDENTITY` for auto-increment, or `UUID` for distributed systems.
- **Foreign Keys:** Enforce with `FOREIGN KEY` + `ON DELETE` policy.
- **Composite Indexes:** Equality columns first, then range/sort columns (e.g., `(status, created_at DESC)`).
- **Partial Indexes:** `WHERE status = 'active'` to shrink index size.
- **Covering Indexes / Index-Only Scans:** `INCLUDE (col)` to avoid heap fetch.
- **BRIN for naturally ordered huge tables** (time-series, append-only logs).
- **Expression/Function Indexes:** `CREATE INDEX ... ON t (lower(email))` for case-insensitive lookups.
- **Monitoring:** Find bloat/unused indexes with `pg_stat_user_indexes` / `pg_stat_statements`; drop redundant ones.

### 3. Schema Design

- **Naming:** lowercase snake_case tables/columns (`user_accounts`, `created_at`); avoid reserved words.
- **Types:** Prefer specific types (`BOOLEAN`, `INTEGER`, `BIGINT`, `NUMERIC`, `TEXT`, `TIMESTAMP WITH TIME ZONE`, `UUID`). Use `TIMESTAMPTZ` for absolute time.
- **Soft Delete:** add `deleted_at TIMESTAMPTZ NULL`; filter `WHERE deleted_at IS NULL`.
- **Constraints:** `NOT NULL`, `UNIQUE`, `CHECK`, `FK` at DB level for integrity.
- **Normalization vs denormalization:** normalize by default; denormalize only with measured need.

### 4. Migrations

- **Idempotent:** use `IF NOT EXISTS` / `IF EXISTS`; safe to re-run.
- **One logical change per migration** for easy rollback.
- **Large tables:** add columns with a non-locking `DEFAULT` (PG 11+); create indexes `CONCURRENTLY` (runs outside a transaction).
- **Test on a prod-like copy** before production.
- **Reversible:** provide `down` steps where possible.

### 5. Security

- **Least Privilege:** app users get only needed grants; never superuser for app connections.
- **Row-Level Security:** `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` + policies for multi-tenant isolation.
- **Secrets:** connection strings/credentials in env vars or a vault; never hardcode.
- **Connection Pooling:** `pgbouncer` (transaction mode) or app-level pools (Hikari, `psycopg2-pool`). Size ~ 2–4 × CPU cores.
- **Audit:** `pgaudit` for sensitive-table access; strip secrets from logs.

### 6. Transactions & Locking

- Keep transactions **short** to limit lock duration and bloat.
- Choose isolation: `READ COMMITTED` default; `REPEATABLE READ` / `SERIALIZABLE` only when required.
- Use `SELECT ... FOR UPDATE SKIP LOCKED` for queue/worker patterns.
- Avoid long-lived idle-in-transaction sessions (they block `VACUUM` and cause bloat).

### 7. Advanced Query Patterns

- **Window Functions:** running totals, rankings, gaps-and-islands.
- **Partitioning:** range (time) / list / hash for very large tables; pair with BRIN + partial indexes.
- **Upsert:** `INSERT ... ON CONFLICT (key) DO UPDATE SET ... = EXCLUDED....`
- **Pagination:** keyset (`WHERE id > $1 ORDER BY id LIMIT n`) beats `OFFSET` on deep pages.
- **Batch DML:** chunk `DELETE`/`UPDATE` to limit lock and WAL pressure.

### 8. Maintenance & Monitoring

- **VACUUM/ANALYZE:** autovacuum tuned for write-heavy tables; manual `VACUUM (ANALYZE, VERBOSE)` when needed.
- **Slow queries:** enable `log_min_duration_statement` (e.g., 1000ms); use `pg_stat_statements`.
- **Replication lag:** monitor standby with `pg_stat_replication` / `pg_stat_wal_receiver`.
- **Backups:** `pg_basebackup` + WAL archiving (PITR); verify restores periodically.

## Common Safe Query Patterns

**SELECT with WHERE/ORDER/LIMIT:**
```sql
SELECT user_id, username, email
FROM users
WHERE status = $1 AND created_at > $2
ORDER BY created_at DESC
LIMIT $3 OFFSET $4;
```

**JOIN with aggregation:**
```sql
SELECT u.user_id, u.username, COUNT(o.order_id) AS order_count
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.status = $1
GROUP BY u.user_id, u.username
HAVING COUNT(o.order_id) > $2
ORDER BY order_count DESC;
```

**CTE:**
```sql
WITH active_users AS (
  SELECT user_id, username FROM users WHERE status = 'active'
)
SELECT au.user_id, au.username, COUNT(o.order_id) AS total_orders
FROM active_users au
LEFT JOIN orders o ON au.user_id = o.user_id
GROUP BY au.user_id, au.username;
```

**Upsert (ON CONFLICT):**
```sql
INSERT INTO users (user_id, username, email)
VALUES ($1, $2, $3)
ON CONFLICT (user_id) DO UPDATE
SET email = EXCLUDED.email, updated_at = NOW();
```

**Keyset pagination:**
```sql
SELECT id, created_at
FROM events
WHERE created_at < $1
ORDER BY created_at DESC
LIMIT $2;
```

**Partitioned table (range by month):**
```sql
CREATE TABLE metrics (
  id BIGINT GENERATED ALWAYS AS IDENTITY,
  recorded_at TIMESTAMPTZ NOT NULL,
  payload JSONB
) PARTITION BY RANGE (recorded_at);

CREATE TABLE metrics_2026_01 PARTITION OF metrics
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
```

**RLS policy example:**
```sql
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON tenants
  USING (tenant_id = current_setting('app.tenant_id')::BIGINT);
```

## Output Format

When generating SQL or migrations:
1. Brief explanation of logic and optimization choices.
2. SQL with comments on non-obvious parts.
3. Index/constraint recommendations.
4. Verification guidance (`EXPLAIN (ANALYZE, BUFFERS)`, expected row counts, query plan shape).
