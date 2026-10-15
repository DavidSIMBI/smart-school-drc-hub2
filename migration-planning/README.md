# MySQL migration planning (Phase 1)

Status: draft, based on inspection of all 15 files in `supabase/migrations/`. This directory is planning material only. The SQL has not been run against any database, and no application code or real data was changed.

## Draft schema decisions

- Target syntax: MySQL 8.0.16+ with InnoDB and `utf8mb4`, so `CHECK` constraints are enforced.
- Keep source UUID values and all relationship values unchanged as `CHAR(36)`. The application/API supplies UUIDs for new rows; the SQL does not generate or convert identifiers.
- PostgreSQL `TEXT` maps to `TEXT`/`VARCHAR`, `JSONB` to `JSON`, `TIMESTAMPTZ` to UTC `DATETIME(3)`, `DATE` to `DATE`, `TIME` to `TIME`, `BIGINT` to `BIGINT`, and `NUMERIC(p,s)` to `DECIMAL(p,s)`. PostgreSQL unconstrained `NUMERIC` is tentatively `DECIMAL(18,2)` for fee amounts; confirm expected max precision before implementation.
- PostgreSQL enum values map to `VARCHAR` plus `CHECK` constraints. This keeps values explicit while allowing a future controlled expansion.
- `auth.users` is not an application table in the supplied migrations. The draft introduces `app_users` as a local identity table so migrated `user_id`, `actor_id`, sender/recipient, and profile references can retain their UUIDs. The exact authentication columns and credential migration are unresolved.
- The draft includes declared FKs and unique/index definitions present across the migration history. Where the original schema intentionally has no FK (for example bookmark targets and resource upload history references), it does not invent one.
- The original policies are summarized in the mapping. Their behavior must move to Express authorization and scoped SQL queries; MySQL does not provide PostgreSQL RLS.

## Files

- `schema.mysql.sql` — proposed DDL, not applied.
- `schema-mapping.md` — source inventory, full table/column map, constraints, policy/function/trigger translation, non-SQL dependencies, and open decisions.

## Source migrations inspected

All 15 migration files were read, including the final policy/constraint revisions:

1. `20260725120652_f94acc0b-c51f-4af5-82a5-6eca9dcd3a4a.sql`
2. `20260725122419_409b43bd-f0bc-4d00-ab28-346530f42139.sql`
3. `20260725123728_cbfefd54-d29f-4512-bdd3-bd1a96ea2b95.sql`
4. `20260726122154_27f8ac61-abd5-4435-b6ec-bcf4ffd253ab.sql`
5. `20260726122940_f389101e-4c38-4624-aa21-dddca6f003bf.sql`
6. `20260726123001_9be9c1b6-b6bd-4b7c-ba2a-1ea063f83b3b.sql`
7. `20260726124638_c42a0d99-f2b1-4e4b-b2cc-5e01139dc3cc.sql`
8. `20260730131010_187ed427-60a3-46c6-8199-b2731551a180.sql`
9. `20260730131046_67da6f15-919b-441f-abbf-fc4164b5dcc3.sql`
10. `20260803170753_84cbcb77-e158-4348-8b40-b3faa6afad29.sql`
11. `20260803171920_a73e6ebf-fb8b-4845-a627-2907c28c9de0.sql`
12. `20260804165619_9a1f174c-f17e-4b27-84f6-c44de299e76b.sql`
13. `20260806202157_d11fb5fe-3534-4edc-9f95-3cf7c75c8f97.sql`
14. `20260807172338_ea196a58-1d3a-45a6-89fd-56cb69151737.sql`
15. `20260807184627_1590fda5-41ba-4759-95f1-222d3e8e6071.sql`
