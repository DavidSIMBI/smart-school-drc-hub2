# PostgreSQL → MySQL schema mapping

This inventory describes the final state represented by the 15 checked-in migrations, not necessarily the current live Supabase schema. Validate against a live schema-only export before implementation. Seed statements in migration 2 are not treated as proof of real production rows.

## Migration history and behavior

| Migration | Schema / behavior added or revised |
|---|---|
| `20260725120652…` | `app_role`; schools, profiles, user_roles, classes, subjects, students, teachers, announcements, documents; initial RLS; role/school helper functions; Auth signup trigger. |
| `20260725122419…` | School status/logo/plan; subscriptions, platform payments, notifications, activity/audit logs, platform settings; timestamp triggers and demo/initial seed statements. |
| `20260725123728…` | Tightens school/settings access; removes public school/settings reads; role-helper execute grants narrowed. |
| `20260726122154…` | Notification read and write policies; explicit super-admin role write policies. |
| `20260726122940…` | Attendance, assignments/submissions, exams/results, lesson plans, teacher docs, messages, calendar, teacher notifications, relationship mapping; three domain enums; timestamps and realtime publication. |
| `20260726123001…` | Initial teacher-materials storage object policies. |
| `20260726124638…` | Student contact/photo columns; timetable slots, bookmarks; student-only record/submission policies. |
| `20260730131010…` | School/academic profile extensions, class/teacher/student/announcement extensions, fee structures/payments and policies, fee indexes/triggers. |
| `20260730131046…` | School-assets storage object policies. |
| `20260803170753…` | School notification UPDATE role restriction. |
| `20260803171920…` | Finance/student visibility policies; self-only restrictions for role helper functions. |
| `20260804165619…` | Teaching resources, upload history, exam questions, assignment/submission/exam extensions; timestamp triggers, indexes, notification helper. |
| `20260806202157…` | Orphan cleanup, missing timetable/class/fee FKs, unique indexes, query indexes. Note: this migration deletes/deduplicates rows on PostgreSQL before adding constraints; do not replay those cleanup statements against data without a separate data-reconciliation decision. |
| `20260807172338…` | Notification policies, storage ownership helper and revised storage rules; changes notification helper from authenticated same-school caller to service-role caller-supplied actor. |
| `20260807184627…` | Submission file metadata and status columns. |

## Final table and column mapping

Types shown below are PostgreSQL source types. `UUID` references should remain identical UUID values in MySQL `CHAR(36)` in the proposed draft. Defaults shown are source defaults. `created_at`/`updated_at` defaults are generally `now()` unless stated otherwise.

| Table | Columns (source type; `*` = NOT NULL; `PK` = primary key) | Relationships / uniqueness / indexes |
|---|---|---|
| `schools` | `id UUID* PK`, `name TEXT*`, `province TEXT*`, `city TEXT*`, `address TEXT`, `phone TEXT`, `email TEXT`, `principal_name TEXT`, `slug TEXT UNIQUE`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*`; later: `status TEXT* DEFAULT pending` CHECK pending/active/suspended, `logo_url TEXT`, `subscription_plan TEXT* DEFAULT trial`, `motto TEXT`, `cover_url TEXT`, `territory TEXT`, `website TEXT`, `facebook TEXT`, `whatsapp TEXT`, `primary_color TEXT`, `secondary_color TEXT`, `accent_color TEXT`, `stamp_url TEXT`, `signature_url TEXT`, `academic_year TEXT`, `current_term TEXT`, `locale TEXT* DEFAULT fr`, `currency TEXT* DEFAULT CDF`, `timezone TEXT* DEFAULT Africa/Kinshasa` | Parent tenant for most school-owned records; slug unique. |
| `profiles` | `id UUID* PK`, `school_id UUID`, `full_name TEXT`, `email TEXT`, `phone TEXT`, `avatar_url TEXT`, `locale TEXT DEFAULT fr`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*` | `id → auth.users(id) ON DELETE CASCADE`; `school_id → schools(id) ON DELETE SET NULL`. |
| `user_roles` | `id UUID* PK`, `user_id UUID*`, `role app_role*`, `school_id UUID`, `created_at TIMESTAMPTZ*` | `user_id → auth.users ON DELETE CASCADE`; `school_id → schools ON DELETE CASCADE`; unique `(user_id, role, school_id)`. Enum values: super_admin, school_admin, secretary, accountant, teacher, student, parent. PostgreSQL NULL semantics mean multiple rows with NULL `school_id` may pass this unique constraint. |
| `classes` | `id UUID* PK`, `school_id UUID*`, `name TEXT*`, `level TEXT`, `academic_year TEXT`, `created_at TIMESTAMPTZ*`; later `section TEXT`, `class_teacher_id UUID` | `school_id → schools ON DELETE CASCADE`; `class_teacher_id → teachers ON DELETE SET NULL`. |
| `subjects` | `id UUID* PK`, `school_id UUID*`, `name TEXT*`, `code TEXT`, `created_at TIMESTAMPTZ*` | `school_id → schools ON DELETE CASCADE`. |
| `students` | `id UUID* PK`, `school_id UUID*`, `class_id UUID`, `user_id UUID`, `first_name TEXT*`, `last_name TEXT*`, `matricule TEXT`, `gender TEXT`, `date_of_birth DATE`, `guardian_name TEXT`, `guardian_phone TEXT`, `created_at TIMESTAMPTZ*`; extensions `email TEXT`, `phone TEXT`, `address TEXT`, `emergency_contact TEXT`, `medical_info TEXT`, `photo_url TEXT`, `status TEXT* DEFAULT active` | `school_id → schools CASCADE`; `class_id → classes SET NULL`; `user_id → auth.users SET NULL`; index `students_user_idx(user_id)`. No uniqueness constraint on matricule in migrations. |
| `teachers` | `id UUID* PK`, `school_id UUID*`, `user_id UUID`, `first_name TEXT*`, `last_name TEXT*`, `email TEXT`, `phone TEXT`, `specialty TEXT`, `created_at TIMESTAMPTZ*`; extensions `photo_url TEXT`, `qualification TEXT`, `status TEXT* DEFAULT active` | `school_id → schools CASCADE`; `user_id → auth.users SET NULL`; index `teachers_user_idx(user_id)`. |
| `announcements` | `id UUID* PK`, `school_id UUID*`, `author_id UUID`, `title TEXT*`, `body TEXT`, `audience TEXT DEFAULT all`, `created_at TIMESTAMPTZ*`; extensions `image_url TEXT`, `attachment_url TEXT`, `publish_at TIMESTAMPTZ`, `status TEXT* DEFAULT published` | `school_id → schools CASCADE`; `author_id → auth.users SET NULL`. |
| `documents` | `id UUID* PK`, `school_id UUID*`, `uploader_id UUID`, `name TEXT*`, `url TEXT`, `category TEXT`, `created_at TIMESTAMPTZ*` | `school_id → schools CASCADE`; `uploader_id → auth.users SET NULL`. |
| `subscriptions` | `id UUID* PK`, `school_id UUID*`, `plan TEXT* DEFAULT trial`, `status TEXT* DEFAULT trialing` CHECK trialing/active/past_due/canceled/expired, `monthly_price NUMERIC(10,2)* DEFAULT 0`, `currency TEXT* DEFAULT USD`, `current_period_start TIMESTAMPTZ* DEFAULT now()`, `current_period_end TIMESTAMPTZ* DEFAULT now()+30 days`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*` | `school_id → schools CASCADE`; timestamp trigger; no unique school constraint (multiple subscriptions per school allowed by source). |
| `payments` (platform subscriptions) | `id UUID* PK`, `school_id UUID*`, `subscription_id UUID`, `amount NUMERIC(10,2)*`, `currency TEXT* DEFAULT USD`, `status TEXT* DEFAULT pending` CHECK pending/paid/failed/refunded, `method TEXT`, `paid_at TIMESTAMPTZ`, `created_at TIMESTAMPTZ*` | `school_id → schools CASCADE`; `subscription_id → subscriptions SET NULL`. |
| `notifications` | `id UUID* PK`, `type TEXT*`, `title TEXT*`, `message TEXT`, `school_id UUID`, `read BOOLEAN* DEFAULT false`, `severity TEXT* DEFAULT info` CHECK info/success/warning/critical, `created_at TIMESTAMPTZ*` | `school_id → schools SET NULL`. |
| `activity_logs` | `id UUID* PK`, `actor_id UUID`, `actor_name TEXT`, `action TEXT*`, `target_type TEXT`, `target_id UUID`, `school_id UUID`, `metadata JSONB DEFAULT {}`, `created_at TIMESTAMPTZ*` | actor → auth users SET NULL; school → schools SET NULL. Target is polymorphic, no FK. |
| `audit_logs` | `id UUID* PK`, `actor_id UUID`, `event TEXT*`, `ip_address TEXT`, `user_agent TEXT`, `metadata JSONB DEFAULT {}`, `created_at TIMESTAMPTZ*` | actor → auth users SET NULL. |
| `platform_settings` | `id UUID* PK`, `platform_name TEXT* DEFAULT SmartSchool RDC`, `logo_url TEXT`, `default_locale TEXT* DEFAULT fr`, `default_theme TEXT* DEFAULT light`, `support_email TEXT`, `notifications_enabled BOOLEAN* DEFAULT true`, `backups_enabled BOOLEAN* DEFAULT true`, `backup_frequency TEXT* DEFAULT daily`, `updated_at TIMESTAMPTZ*` | Timestamp trigger. No singleton constraint is present, though code often selects one row. |
| `teacher_class_subjects` | `id UUID* PK`, `school_id UUID*`, `teacher_id UUID*`, `class_id UUID*`, `subject_id UUID*`, `weekly_hours NUMERIC(4,1)* DEFAULT 0`, `schedule JSONB* DEFAULT []`, `created_at TIMESTAMPTZ*` | school/teacher/class/subject FKs all CASCADE; unique `(teacher_id,class_id,subject_id)` (also named unique index in later migration). |
| `attendance_sessions` | `id UUID* PK`, `school_id UUID*`, `teacher_id UUID*`, `class_id UUID*`, `subject_id UUID`, `session_date DATE* DEFAULT CURRENT_DATE`, `notes TEXT`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*` | school/teacher/class CASCADE; subject SET NULL; updated timestamp trigger. |
| `attendance_records` | `id UUID* PK`, `session_id UUID*`, `student_id UUID*`, `status attendance_status* DEFAULT present`, `created_at TIMESTAMPTZ*` | session/student CASCADE; unique `(session_id,student_id)`; enum present/absent/late/excused. |
| `assignments` | `id UUID* PK`, `school_id UUID*`, `teacher_id UUID*`, `class_id UUID*`, `subject_id UUID`, `title TEXT*`, `instructions TEXT`, `due_date TIMESTAMPTZ`, `attachments JSONB* DEFAULT []`, `status assignment_status* DEFAULT open`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*`; extensions `open_at TIMESTAMPTZ`, `allow_late BOOLEAN* DEFAULT false`, `max_score NUMERIC* DEFAULT 20`, `published_at TIMESTAMPTZ` | school/teacher/class CASCADE; subject SET NULL; `assignments_class_idx(class_id)`; updated timestamp trigger; enum open/closed/archived. |
| `assignment_submissions` | `id UUID* PK`, `assignment_id UUID*`, `student_id UUID*`, `content TEXT`, `file_url TEXT`, `submitted_at TIMESTAMPTZ* DEFAULT now()`, `grade NUMERIC(6,2)`, `feedback TEXT`; extensions `is_late BOOLEAN* DEFAULT false`, `graded_at TIMESTAMPTZ`, `graded_by UUID`, `grade_published BOOLEAN* DEFAULT false`, `returned_at TIMESTAMPTZ`, `file_path TEXT`, `file_name TEXT`, `file_type TEXT`, `file_size BIGINT`, `status TEXT* DEFAULT submitted` | assignment/student CASCADE; unique `(assignment_id,student_id)` (later unique index). `graded_by` has no declared FK. |
| `exams` | `id UUID* PK`, `school_id UUID*`, `teacher_id UUID*`, `class_id UUID*`, `subject_id UUID`, `title TEXT*`, `exam_date DATE`, `max_score NUMERIC(6,2)* DEFAULT 100`, `term TEXT`, `status exam_status* DEFAULT draft`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*`; extensions `duration_minutes INTEGER`, `available_from TIMESTAMPTZ`, `available_to TIMESTAMPTZ`, `randomize BOOLEAN* DEFAULT false`, `document_url TEXT`, `exam_kind TEXT* DEFAULT document` | school/teacher/class CASCADE; subject SET NULL; `exams_class_idx(class_id)`; updated trigger; enum draft/published. |
| `exam_results` | `id UUID* PK`, `exam_id UUID*`, `student_id UUID*`, `score NUMERIC(6,2)`, `grade TEXT`, `position INTEGER`, `comment TEXT` | exam/student CASCADE; unique `(exam_id,student_id)`. |
| `lesson_plans` | `id UUID* PK`, `school_id UUID*`, `teacher_id UUID*`, `class_id UUID`, `subject_id UUID`, `title TEXT*`, `week TEXT`, `objectives TEXT`, `content TEXT`, `resources JSONB* DEFAULT []`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*` | school/teacher CASCADE; class/subject SET NULL; updated trigger. |
| `teacher_documents` | `id UUID* PK`, `school_id UUID*`, `teacher_id UUID*`, `class_id UUID`, `subject_id UUID`, `name TEXT*`, `url TEXT*`, `kind TEXT`, `size_bytes BIGINT`, `created_at TIMESTAMPTZ*` | school/teacher CASCADE; class/subject SET NULL. |
| `messages` | `id UUID* PK`, `school_id UUID*`, `sender_id UUID*`, `recipient_id UUID*`, `subject TEXT`, `body TEXT*`, `read_at TIMESTAMPTZ`, `created_at TIMESTAMPTZ*` | school/sender/recipient CASCADE; realtime publication for `messages`. |
| `calendar_events` | `id UUID* PK`, `school_id UUID*`, `owner_id UUID`, `title TEXT*`, `description TEXT`, `kind TEXT* DEFAULT event`, `starts_at TIMESTAMPTZ*`, `ends_at TIMESTAMPTZ`, `audience TEXT* DEFAULT school`, `created_at TIMESTAMPTZ*` | school CASCADE; owner → auth users SET NULL. |
| `teacher_notifications` | `id UUID* PK`, `user_id UUID*`, `school_id UUID`, `type TEXT*`, `title TEXT*`, `body TEXT`, `read BOOLEAN* DEFAULT false`, `created_at TIMESTAMPTZ*` | user CASCADE; school CASCADE; realtime publication. |
| `timetable_slots` | `id UUID* PK`, `school_id UUID*`, `class_id UUID*`, `subject_id UUID`, `teacher_id UUID`, `day_of_week SMALLINT* CHECK 1–7`, `start_time TIME*`, `end_time TIME*`, `room TEXT`, `created_at TIMESTAMPTZ*` | school/class CASCADE; subject/teacher SET NULL; indexes on class and teacher. No timetable clash constraint. |
| `student_bookmarks` | `id UUID* PK`, `user_id UUID*`, `target_type TEXT*`, `target_id UUID*`, `created_at TIMESTAMPTZ*` | unique `(user_id,target_type,target_id)`; target is polymorphic and has no FK. |
| `fee_structures` | `id UUID* PK`, `school_id UUID*`, `class_id UUID`, `name TEXT*`, `description TEXT`, `amount NUMERIC* DEFAULT 0`, `currency TEXT* DEFAULT CDF`, `term TEXT`, `academic_year TEXT`, `due_date DATE`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*` | school CASCADE; class SET NULL; index `idx_fee_structures_school(school_id)`; update trigger. |
| `fee_payments` | `id UUID* PK`, `school_id UUID*`, `student_id UUID*`, `fee_structure_id UUID`, `amount NUMERIC* DEFAULT 0`, `currency TEXT* DEFAULT CDF`, `method TEXT`, `reference TEXT`, `receipt_no TEXT`, `status TEXT* DEFAULT paid`, `paid_at TIMESTAMPTZ* DEFAULT now()`, `note TEXT`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*` | school/student CASCADE; fee_structure SET NULL; index `idx_fee_payments_student(student_id)`; update trigger. No uniqueness for receipt number. |
| `teaching_resources` | `id UUID* PK`, `school_id UUID*`, `teacher_id UUID*`, `class_id UUID`, `subject_id UUID`, `academic_year TEXT`, `term TEXT`, `topic TEXT`, `title TEXT*`, `description TEXT`, `resource_type TEXT* DEFAULT note` CHECK note/presentation/video/video_link/image/reference, `storage_path TEXT`, `external_url TEXT`, `file_name TEXT`, `mime_type TEXT`, `size_bytes BIGINT`, `publish_at TIMESTAMPTZ* DEFAULT now()`, `due_date TIMESTAMPTZ`, `status TEXT* DEFAULT published` CHECK draft/scheduled/published, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*` | school/teacher CASCADE; class/subject SET NULL; indexes school and class; update trigger. |
| `resource_upload_history` | `id UUID* PK`, `school_id UUID*`, `resource_id UUID`, `actor_id UUID`, `actor_name TEXT`, `action TEXT*`, `details JSONB* DEFAULT {}`, `created_at TIMESTAMPTZ*` | school CASCADE; resource/actor intentionally lack declared FKs; index `(school_id,created_at DESC)`. |
| `exam_questions` | `id UUID* PK`, `exam_id UUID*`, `school_id UUID*`, `kind TEXT* DEFAULT mcq` CHECK mcq/truefalse/short, `prompt TEXT*`, `options JSONB* DEFAULT []`, `correct_answer TEXT`, `points NUMERIC* DEFAULT 1`, `order_index INTEGER* DEFAULT 0`, `created_at TIMESTAMPTZ*`, `updated_at TIMESTAMPTZ*` | exam/school CASCADE; index `(exam_id,order_index)`; update trigger. |

## Primary keys, FK actions, indexes, and unique rules

- All declared entity primary keys are UUIDs. The child tables `attendance_records`, `exam_results`, etc. still have their own UUID primary key; none use composite primary keys.
- Explicit FK delete actions are recorded in the table map. Several initial columns did not have declared FKs until migration 13 (timetable, class teacher, fees); the final state includes them.
- Unique rules: `schools.slug`; `user_roles(user_id,role,school_id)`; `teacher_class_subjects(teacher_id,class_id,subject_id)`; `attendance_records(session_id,student_id)`; `assignment_submissions(assignment_id,student_id)`; `exam_results(exam_id,student_id)`; `student_bookmarks(user_id,target_type,target_id)`.
- Explicit non-unique indexes: `idx_fee_payments_student`, `idx_fee_structures_school`, `idx_teaching_resources_school`, `idx_teaching_resources_class`, `idx_resource_upload_history_school(school_id,created_at DESC)`, `idx_exam_questions_exam(exam_id,order_index)`, `timetable_slots_class_idx`, `timetable_slots_teacher_idx`, `teaching_resources_class_idx`, `assignments_class_idx`, `exams_class_idx`, `students_user_idx`, `teachers_user_idx`. Some index definitions duplicate a table-level unique constraint by design/history.
- No `ON UPDATE CASCADE` relationships are declared. Update triggers modify timestamp fields only.

## RLS policy translation to Express

MySQL offers no equivalent to this PostgreSQL RLS setup. Express must authenticate each request, resolve the user's UUID, roles, and school server-side, then add scope conditions to every query and authorize writes against the target record. Never use a browser-supplied `school_id` as authority. Use transactions for authorization-sensitive multi-row writes and return consistent 403/404 behavior to avoid cross-school record enumeration.

Policy groups in the final migration state:

- **Tenant tables (classes, subjects, students, teachers, announcements, documents, attendance, assignments, exams, lesson plans, teacher docs, timetable):** generally allow same-school members and super-admin; special rules apply to student own records, assignment submissions, teacher assignments, timetable manager roles, and question/resource ownership.
- **Schools/profiles/roles:** school members or super-admin read schools; signup may create a school only when caller has no school or is super-admin. Profiles are self-readable/writable, school-visible, and super-admin manageable. Users can read own roles; school admins can read school roles; only super-admin writes roles.
- **Fees:** school admin/accountant/secretary manage. Finance roles read structures and payments; students read structures applicable to own class and only their own fee payments. Super-admin access is explicit.
- **Platform subscriptions/payments:** super-admin manages; school admin/accountant reads only their school's entries.
- **Messages/calendar/notifications:** sender or recipient rules for messages; owner rules for calendar writes; per-user notification rules; school notifications are readable by school users, with role-specific create/update/delete policies.
- **Activity/audit/platform settings:** activity users can insert their own records; school-scoped/super-admin reads. Audit inserts actor-self and reads super-admin only. Settings ended restricted to super-admin in the later migrations.
- **Storage objects:** school-assets and teacher-materials require bucket-specific rules, first path segment matching the signed-in user's school, owner checks for writes, and super-admin read. The final migration adds `owns_school_folder` validation against the profile-school relationship.

The old migrations contain dropped/replaced policies; implement the final policy behavior above, not every historical policy as additive logic. Several policies use broad `FOR ALL`, so confirm intended effective permissions when writing endpoint-level authorization tests.

### Final policy-name inventory (including storage policies)

This lists created policy names from the supplied files; for policy names later dropped/replaced, use the final behavior in the preceding summary. Historical policies removed by migration 3/4 include `Public can view schools basic`, `Authenticated can create school`, `Anyone reads settings`, and the earlier `Authenticated read settings`.

- Schools: `Members view their school`, `Authenticated without school can create one`, `School admins can update own school`, `Super admin manages schools`.
- Profiles: `Users read own profile`, `Users insert own profile`, `Users update own profile`, `Super admin manages profiles`.
- Roles: `Users read own roles`, `Super admin inserts roles`, `Super admin updates roles`, `Super admin deletes roles`.
- School records: `School members access classes`, `School members access subjects`, `School members access students` (later additional `Students read own record`), `School members access teachers`, `School members access announcements`, `School members access documents`.
- Platform/comms: `Super admin manages subscriptions`, `School admin reads own subscription` (later admin/accountant), `Super admin manages payments`, `School admin reads own payments` (later admin/accountant), `Super admin manages notifications`, `School members read school notifications`, `School admins update school notifications`, `School admins insert school notifications`, `School admins delete school notifications`, `Super admin reads all activity`, `Users insert own activity`, `School members read school activity`, `Super admin reads audit`, `Users insert own audit`, `Super admin manages settings`.
- Teaching: `school members access tcs`, `school members access attendance_sessions`, `school members access attendance_records`, `school members access assignments`, `school members access submissions` (later `Students access own submissions`), `school members access exams`, `school members access exam_results`, `school members access lesson_plans`, `school members access teacher_documents`, `sender or recipient reads`, `sender inserts`, `recipient marks read`, `sender deletes`, `school members read calendar`, `owner writes calendar`, `owner updates calendar`, `owner deletes calendar`, `own notifications`.
- Timetable/bookmarks: `School members read timetable`, `Admins manage timetable`, `Users manage own bookmarks`.
- Fees: `fee_structures_school_manage`, `fee_structures_finance_read`, `fee_structures_student_read`, `fee_payments_school_manage`, `fee_payments_finance_read`, `fee_payments_student_read` (initial `fee_structures_school_read` and `fee_payments_school_read` were dropped/replaced).
- Resources/questions: `Staff read school resources`, `Students read published resources`, `Teachers manage own resources`, `School admins manage resources`, `Staff read upload history`, `Actors write upload history`, `Teachers manage own exam questions`, `School admins manage exam questions`.
- Storage objects: `school_assets_read`, `school_assets_insert`, `school_assets_update`, `school_assets_delete`, `teacher-materials read school`, `teacher-materials owner writes`, `teacher-materials owner updates`, `teacher-materials owner deletes` (later rewritten to call `owns_school_folder`).

### Functions and triggers in final migrations

- `has_role(user_id, role)`, `is_super_admin(user_id)`, `get_user_school(user_id)`: SECURITY DEFINER SQL helpers. Later revision prevents authenticated callers querying another user's role/school context; execute revoked from anon/public.
- `handle_new_user()`: inserts a profile from `auth.users` email and `raw_user_meta_data.full_name`; attached by trigger `on_auth_user_created` AFTER INSERT on `auth.users`. Execute revoked from client roles in migration 3/4.
- `set_updated_at()`: assigns `NEW.updated_at = now()`; triggers `trg_subscriptions_updated`, `trg_platform_settings_updated`, `trg_attendance_sessions_updated`, `trg_assignments_updated`, `trg_exams_updated`, `trg_lesson_plans_updated`, `set_fee_structures_updated_at`, `set_fee_payments_updated_at`, `trg_teaching_resources_updated`, `trg_exam_questions_updated`. Execute revoked from client roles.
- `notify_school_user(user_id,type,title,body)`: checks caller and recipient profiles share a non-null school, then inserts a teacher notification. Later execute privilege is revoked for all app/client roles.
- `notify_user_as(caller_id,user_id,type,title,body)`: server/service-role function checks same-school membership, truncates body to 2,000 characters, inserts a teacher notification. Execute granted only to `service_role`.
- `owns_school_folder(path)`: checks the authenticated user's profile school matches the first storage path component and that school exists; used by final storage policies.
- Realtime publication adds `messages` and `teacher_notifications`.

### Exact named indexes / unique constraints from source

In addition to each table's PK, the source names: `schools.slug` unique; `teacher_class_subjects_unique_idx(teacher_id,class_id,subject_id)`; `assignment_submissions_unique_idx(assignment_id,student_id)`; `timetable_slots_class_idx(class_id)`; `timetable_slots_teacher_idx(teacher_id)`; `teaching_resources_class_idx(class_id)`; `assignments_class_idx(class_id)`; `exams_class_idx(class_id)`; `students_user_idx(user_id)`; `teachers_user_idx(user_id)`; `idx_fee_payments_student(student_id)`; `idx_fee_structures_school(school_id)`; `idx_teaching_resources_school(school_id)`; `idx_teaching_resources_class(class_id)` (same logical index as above, created once in source); `idx_resource_upload_history_school(school_id,created_at DESC)`; `idx_exam_questions_exam(exam_id,order_index)`. Table-level unique constraints are listed under each table. Foreign-key supporting indexes may be created implicitly by PostgreSQL or MySQL and are not counted as source-named indexes.

## PostgreSQL-only features and replacements

| PostgreSQL feature | MySQL / Express plan |
|---|---|
| `UUID`, `gen_random_uuid()` | Preserve existing UUID text exactly as `CHAR(36)`. Generate new UUIDs in Node; do not rely on database-generated IDs in the first migration. |
| `TIMESTAMPTZ`, `now()`, intervals | Store UTC `DATETIME(3)`; normalize inbound/outbound values to UTC. Replace interval arithmetic in app code or MySQL expressions. |
| `JSONB` operators/defaults | MySQL `JSON`; app code performs validation and serialization. Query paths using JSON operators need query-specific rewrites. |
| PostgreSQL enums | `VARCHAR` with `CHECK`, or lookup table if role/value lifecycle needs administration. Preserve exact current labels. |
| `SERIAL`/sequence behavior | None used for application primary keys; keep UUIDs. |
| RLS, `auth.uid()`, `SECURITY DEFINER` | Express auth middleware + role helpers + query-scoped SQL. Do not expose DB directly to frontend. Replace helper functions with server-only services. |
| Trigger `set_updated_at()` | Set `updated_at` in update service/repository layer consistently; optional MySQL trigger only if a clear need emerges. |
| `handle_new_user()` Auth trigger | Replace with transactional account creation that creates `app_users`, profile, role, and any school relationship. Email-confirmation workflow is separate. |
| `notify_school_user`/`notify_user_as` RPC | Replace with a server-only notification service that confirms same-school relationship and writes within a transaction; validate the caller from session, not request body. |
| Storage policies and `storage.foldername()` | Replace with a storage adapter and authorization service checking actual DB school membership, bucket/type/size, ownership, and opaque object keys. Never trust path alone. |
| `ALTER PUBLICATION supabase_realtime` | Supabase Realtime is not MySQL behavior. Decide whether polling, Server-Sent Events, or a separate websocket layer is needed. |
| `ON CONFLICT`, `generate_series`, `unnest`, PostgreSQL casts | Rewrite seed/import/query logic for MySQL. These appear in demo seed statements; do not replay them blindly as a production import. |
| RLS grants/revokes | MySQL DB account should be least-privileged to application schema. App authorization enforces user roles; separate admin/migration DB credentials must be kept server-only. |

## Supabase dependencies not solved by SQL translation

- **Supabase Auth:** `auth.users` supplies identity, sessions, email confirmation, password reset, OAuth, token validation, and user IDs. The migrations refer to this external schema. A local `app_users` table cannot automatically migrate Supabase sessions or prove password hash compatibility. Preserve UUIDs and choose a credential/session transition plan before data import.
- **Supabase Storage:** storage objects and bucket configuration are outside these application-table DDLs. `documents`, `teacher_documents`, submissions, resources, and school profiles contain URLs/paths/metadata, but SQL does not copy the actual bytes, signed URL rules, bucket access controls, or object ownership. Inventory and separately transfer objects.
- **Supabase Realtime:** publication membership does not define replacement delivery semantics. Messaging and teacher notifications may require another transport.
- **Supabase RPC/client API:** the code calls Auth admin methods, storage APIs, query builder operations, and RPC functions; all need service/API replacements beyond schema conversion.

## Open decisions before implementation

1. MySQL server version/hosting and whether this is local-only or later deployed; confirm supported `CHECK` behavior and UTC settings.
2. UUID representation (`CHAR(36)` vs `BINARY(16)`). This draft chooses `CHAR(36)` for migration traceability; binary is smaller but requires conversion and every import/export layer to handle it.
3. Authentication approach: credential re-entry/password reset vs verified hash migration; local session cookie lifetime, email delivery, OAuth, and recovery process.
4. `app_users` identity fields, uniqueness/case rules for email, disabled/deleted state, and whether multiple roles/schools per user remain supported. `user_roles` unique key includes nullable school_id; MySQL unique-NULL semantics must be made explicit (possibly a generated normalized scope key).
5. Numeric precision for unconstrained fee amounts, assignment max score, resource question points; currency scale and rounding policy.
6. Whether application timestamps should be UTC `DATETIME(3)` or MySQL `TIMESTAMP(3)` with its narrower range/conversion behavior.
7. Whether adding missing declared relationships/constraints is allowed. Current schema has polymorphic IDs and loose references (bookmarks, upload history, assignment graded_by), and no same-school composite FK guarantees.
8. Whether to retain PostgreSQL's exact FK delete behavior, especially cascades from school/user deletions into attendance, messages, payments, and submissions; define soft-delete/retention requirements first.
9. `platform_settings` has no single-row constraint; app selects one row. Decide whether to preserve multi-row behavior or enforce singleton safely.
10. `fee_payments.receipt_no` has no uniqueness; `students.matricule` also has none. Confirm business uniqueness and existing duplicate data before adding constraints.
11. Storage destination (local filesystem vs object storage), bucket privacy, public logo semantics, signed URL or proxy behavior, file size/types, path mapping, and retention.
12. Realtime replacement (polling/SSE/websocket) for messages and notifications.
13. PostgreSQL migration 2 contains example seed rows and generated series; establish which live rows are authoritative and whether seed-like records are present before import.
14. The source migrations' cleanup migration deletes orphan timetable/fee rows and deduplicates teacher links/submissions. Decide whether the target import should preserve all source rows, quarantine invalid rows, or match live DB final-state cleanup; do not copy cleanup deletes blindly.
15. Confirm all actual Supabase tables/columns/indexes/policies against a current schema-only export. Checked-in migrations may not match remote drift.
16. `student_bookmarks.target_type` is PostgreSQL `TEXT`; the draft narrows it to `VARCHAR(191)` so the value can participate in a portable unique key. Confirm its full value domain/maximum length or choose a generated hash/key strategy to avoid narrowing source values.
17. MySQL unique indexes cannot use unrestricted `TEXT` columns without a prefix (prefix uniqueness differs from full-value uniqueness); the draft uses bounded `VARCHAR` for `schools.slug`, `app_users.email`, and bookmark `target_type`. Confirm lengths and email collation/case sensitivity before adoption.
