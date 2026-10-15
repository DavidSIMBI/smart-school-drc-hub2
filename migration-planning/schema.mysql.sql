-- DRAFT ONLY. MySQL 8.0.16+ / InnoDB / utf8mb4.
-- Never executed. IDs are CHAR(36) so source UUID strings remain unchanged.
-- This is proposed structural DDL only; authorization is implemented in Express.

CREATE TABLE app_users (
  id CHAR(36) NOT NULL PRIMARY KEY,
  email VARCHAR(320) NOT NULL,
  password_hash VARCHAR(255) NULL,
  email_verified_at DATETIME(3) NULL,
  disabled_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  UNIQUE KEY app_users_email_uq (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE schools (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  province TEXT NOT NULL,
  city TEXT NOT NULL,
  address TEXT NULL,
  phone TEXT NULL,
  email TEXT NULL,
  principal_name TEXT NULL,
  slug VARCHAR(255) NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'pending',
  logo_url TEXT NULL,
  subscription_plan VARCHAR(100) NOT NULL DEFAULT 'trial',
  motto TEXT NULL,
  cover_url TEXT NULL,
  territory TEXT NULL,
  website TEXT NULL,
  facebook TEXT NULL,
  whatsapp TEXT NULL,
  primary_color TEXT NULL,
  secondary_color TEXT NULL,
  accent_color TEXT NULL,
  stamp_url TEXT NULL,
  signature_url TEXT NULL,
  academic_year TEXT NULL,
  current_term TEXT NULL,
  locale VARCHAR(16) NOT NULL DEFAULT 'fr',
  currency VARCHAR(12) NOT NULL DEFAULT 'CDF',
  timezone VARCHAR(80) NOT NULL DEFAULT 'Africa/Kinshasa',
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  UNIQUE KEY schools_slug_uq (slug),
  CONSTRAINT schools_status_ck CHECK (status IN ('pending','active','suspended'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE profiles (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NULL,
  full_name TEXT NULL,
  email TEXT NULL,
  phone TEXT NULL,
  avatar_url TEXT NULL,
  locale VARCHAR(16) NULL DEFAULT 'fr',
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  CONSTRAINT profiles_user_fk FOREIGN KEY (id) REFERENCES app_users(id) ON DELETE CASCADE,
  CONSTRAINT profiles_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE user_roles (
  id CHAR(36) NOT NULL PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  role VARCHAR(24) NOT NULL,
  school_id CHAR(36) NULL,
  created_at DATETIME(3) NOT NULL,
  KEY user_roles_user_idx (user_id),
  KEY user_roles_school_idx (school_id),
  CONSTRAINT user_roles_user_fk FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE,
  CONSTRAINT user_roles_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT user_roles_role_ck CHECK (role IN ('super_admin','school_admin','secretary','accountant','teacher','student','parent'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- Source unique key includes nullable school_id. MySQL allows multiple NULLs in a
-- unique key, as PostgreSQL does by default; verify intended global-role behavior.
CREATE UNIQUE INDEX user_roles_scope_uq ON user_roles(user_id, role, school_id);

CREATE TABLE classes (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  name TEXT NOT NULL,
  level TEXT NULL,
  academic_year TEXT NULL,
  section TEXT NULL,
  class_teacher_id CHAR(36) NULL,
  created_at DATETIME(3) NOT NULL,
  KEY classes_school_idx (school_id),
  CONSTRAINT classes_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE subjects (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  name TEXT NOT NULL,
  code TEXT NULL,
  created_at DATETIME(3) NOT NULL,
  KEY subjects_school_idx (school_id),
  CONSTRAINT subjects_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE students (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  class_id CHAR(36) NULL,
  user_id CHAR(36) NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  matricule TEXT NULL,
  gender TEXT NULL,
  date_of_birth DATE NULL,
  guardian_name TEXT NULL,
  guardian_phone TEXT NULL,
  email TEXT NULL,
  phone TEXT NULL,
  address TEXT NULL,
  emergency_contact TEXT NULL,
  medical_info TEXT NULL,
  photo_url TEXT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'active',
  created_at DATETIME(3) NOT NULL,
  KEY students_school_idx (school_id),
  KEY students_class_idx (class_id),
  KEY students_user_idx (user_id),
  CONSTRAINT students_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT students_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
  CONSTRAINT students_user_fk FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE teachers (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  user_id CHAR(36) NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NULL,
  phone TEXT NULL,
  specialty TEXT NULL,
  photo_url TEXT NULL,
  qualification TEXT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'active',
  created_at DATETIME(3) NOT NULL,
  KEY teachers_school_idx (school_id),
  KEY teachers_user_idx (user_id),
  CONSTRAINT teachers_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT teachers_user_fk FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE classes ADD CONSTRAINT classes_class_teacher_fk
  FOREIGN KEY (class_teacher_id) REFERENCES teachers(id) ON DELETE SET NULL;

CREATE TABLE announcements (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  author_id CHAR(36) NULL,
  title TEXT NOT NULL,
  body TEXT NULL,
  audience VARCHAR(100) NULL DEFAULT 'all',
  image_url TEXT NULL,
  attachment_url TEXT NULL,
  publish_at DATETIME(3) NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'published',
  created_at DATETIME(3) NOT NULL,
  KEY announcements_school_idx (school_id),
  CONSTRAINT announcements_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT announcements_author_fk FOREIGN KEY (author_id) REFERENCES app_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE documents (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  uploader_id CHAR(36) NULL,
  name TEXT NOT NULL,
  url TEXT NULL,
  category TEXT NULL,
  created_at DATETIME(3) NOT NULL,
  KEY documents_school_idx (school_id),
  CONSTRAINT documents_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT documents_uploader_fk FOREIGN KEY (uploader_id) REFERENCES app_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE subscriptions (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  plan VARCHAR(100) NOT NULL DEFAULT 'trial',
  status VARCHAR(24) NOT NULL DEFAULT 'trialing',
  monthly_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  currency VARCHAR(12) NOT NULL DEFAULT 'USD',
  current_period_start DATETIME(3) NOT NULL,
  current_period_end DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  KEY subscriptions_school_idx (school_id),
  CONSTRAINT subscriptions_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT subscriptions_status_ck CHECK (status IN ('trialing','active','past_due','canceled','expired'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE payments (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  subscription_id CHAR(36) NULL,
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(12) NOT NULL DEFAULT 'USD',
  status VARCHAR(16) NOT NULL DEFAULT 'pending',
  method TEXT NULL,
  paid_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL,
  KEY payments_school_idx (school_id),
  CONSTRAINT payments_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT payments_subscription_fk FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL,
  CONSTRAINT payments_status_ck CHECK (status IN ('pending','paid','failed','refunded'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE notifications (
  id CHAR(36) NOT NULL PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NULL,
  school_id CHAR(36) NULL,
  `read` BOOLEAN NOT NULL DEFAULT FALSE,
  severity VARCHAR(16) NOT NULL DEFAULT 'info',
  created_at DATETIME(3) NOT NULL,
  KEY notifications_school_idx (school_id),
  CONSTRAINT notifications_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL,
  CONSTRAINT notifications_severity_ck CHECK (severity IN ('info','success','warning','critical'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE activity_logs (
  id CHAR(36) NOT NULL PRIMARY KEY,
  actor_id CHAR(36) NULL,
  actor_name TEXT NULL,
  action TEXT NOT NULL,
  target_type TEXT NULL,
  target_id CHAR(36) NULL,
  school_id CHAR(36) NULL,
  metadata JSON NULL,
  created_at DATETIME(3) NOT NULL,
  KEY activity_logs_school_idx (school_id),
  KEY activity_logs_actor_idx (actor_id),
  CONSTRAINT activity_logs_actor_fk FOREIGN KEY (actor_id) REFERENCES app_users(id) ON DELETE SET NULL,
  CONSTRAINT activity_logs_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE audit_logs (
  id CHAR(36) NOT NULL PRIMARY KEY,
  actor_id CHAR(36) NULL,
  event TEXT NOT NULL,
  ip_address TEXT NULL,
  user_agent TEXT NULL,
  metadata JSON NULL,
  created_at DATETIME(3) NOT NULL,
  KEY audit_logs_actor_idx (actor_id),
  KEY audit_logs_created_idx (created_at),
  CONSTRAINT audit_logs_actor_fk FOREIGN KEY (actor_id) REFERENCES app_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE platform_settings (
  id CHAR(36) NOT NULL PRIMARY KEY,
  platform_name VARCHAR(255) NOT NULL DEFAULT 'SmartSchool RDC',
  logo_url TEXT NULL,
  default_locale VARCHAR(16) NOT NULL DEFAULT 'fr',
  default_theme VARCHAR(16) NOT NULL DEFAULT 'light',
  support_email TEXT NULL,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  backups_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  backup_frequency VARCHAR(32) NOT NULL DEFAULT 'daily',
  updated_at DATETIME(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE teacher_class_subjects (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  teacher_id CHAR(36) NOT NULL,
  class_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NOT NULL,
  weekly_hours DECIMAL(4,1) NOT NULL DEFAULT 0,
  schedule JSON NOT NULL,
  created_at DATETIME(3) NOT NULL,
  UNIQUE KEY teacher_class_subjects_uq (teacher_id,class_id,subject_id),
  KEY teacher_class_subjects_school_idx (school_id),
  CONSTRAINT tcs_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT tcs_teacher_fk FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
  CONSTRAINT tcs_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT tcs_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE attendance_sessions (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  teacher_id CHAR(36) NOT NULL,
  class_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NULL,
  session_date DATE NOT NULL,
  notes TEXT NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  KEY attendance_sessions_school_date_idx (school_id,session_date),
  CONSTRAINT attendance_sessions_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT attendance_sessions_teacher_fk FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
  CONSTRAINT attendance_sessions_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT attendance_sessions_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE attendance_records (
  id CHAR(36) NOT NULL PRIMARY KEY,
  session_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'present',
  created_at DATETIME(3) NOT NULL,
  UNIQUE KEY attendance_record_student_uq (session_id,student_id),
  CONSTRAINT attendance_records_session_fk FOREIGN KEY (session_id) REFERENCES attendance_sessions(id) ON DELETE CASCADE,
  CONSTRAINT attendance_records_student_fk FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT attendance_records_status_ck CHECK (status IN ('present','absent','late','excused'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE assignments (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  teacher_id CHAR(36) NOT NULL,
  class_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NULL,
  title TEXT NOT NULL,
  instructions TEXT NULL,
  due_date DATETIME(3) NULL,
  attachments JSON NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'open',
  open_at DATETIME(3) NULL,
  allow_late BOOLEAN NOT NULL DEFAULT FALSE,
  max_score DECIMAL(18,2) NOT NULL DEFAULT 20,
  published_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  KEY assignments_class_idx (class_id),
  KEY assignments_school_idx (school_id),
  CONSTRAINT assignments_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT assignments_teacher_fk FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
  CONSTRAINT assignments_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT assignments_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
  CONSTRAINT assignments_status_ck CHECK (status IN ('open','closed','archived'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE assignment_submissions (
  id CHAR(36) NOT NULL PRIMARY KEY,
  assignment_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  content TEXT NULL,
  file_url TEXT NULL,
  submitted_at DATETIME(3) NOT NULL,
  grade DECIMAL(6,2) NULL,
  feedback TEXT NULL,
  is_late BOOLEAN NOT NULL DEFAULT FALSE,
  graded_at DATETIME(3) NULL,
  graded_by CHAR(36) NULL,
  grade_published BOOLEAN NOT NULL DEFAULT FALSE,
  returned_at DATETIME(3) NULL,
  file_path TEXT NULL,
  file_name TEXT NULL,
  file_type TEXT NULL,
  file_size BIGINT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'submitted',
  UNIQUE KEY assignment_submissions_student_uq (assignment_id,student_id),
  CONSTRAINT assignment_submissions_assignment_fk FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
  CONSTRAINT assignment_submissions_student_fk FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE exams (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  teacher_id CHAR(36) NOT NULL,
  class_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NULL,
  title TEXT NOT NULL,
  exam_date DATE NULL,
  max_score DECIMAL(6,2) NOT NULL DEFAULT 100,
  term TEXT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'draft',
  duration_minutes INT NULL,
  available_from DATETIME(3) NULL,
  available_to DATETIME(3) NULL,
  randomize BOOLEAN NOT NULL DEFAULT FALSE,
  document_url TEXT NULL,
  exam_kind VARCHAR(100) NOT NULL DEFAULT 'document',
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  KEY exams_class_idx (class_id),
  KEY exams_school_idx (school_id),
  CONSTRAINT exams_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT exams_teacher_fk FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
  CONSTRAINT exams_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT exams_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
  CONSTRAINT exams_status_ck CHECK (status IN ('draft','published'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE exam_results (
  id CHAR(36) NOT NULL PRIMARY KEY,
  exam_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  score DECIMAL(6,2) NULL,
  grade TEXT NULL,
  position INT NULL,
  comment TEXT NULL,
  UNIQUE KEY exam_results_student_uq (exam_id,student_id),
  CONSTRAINT exam_results_exam_fk FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
  CONSTRAINT exam_results_student_fk FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE lesson_plans (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  teacher_id CHAR(36) NOT NULL,
  class_id CHAR(36) NULL,
  subject_id CHAR(36) NULL,
  title TEXT NOT NULL,
  week TEXT NULL,
  objectives TEXT NULL,
  content TEXT NULL,
  resources JSON NOT NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  CONSTRAINT lesson_plans_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT lesson_plans_teacher_fk FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
  CONSTRAINT lesson_plans_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
  CONSTRAINT lesson_plans_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE teacher_documents (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  teacher_id CHAR(36) NOT NULL,
  class_id CHAR(36) NULL,
  subject_id CHAR(36) NULL,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  kind TEXT NULL,
  size_bytes BIGINT NULL,
  created_at DATETIME(3) NOT NULL,
  CONSTRAINT teacher_documents_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT teacher_documents_teacher_fk FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
  CONSTRAINT teacher_documents_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
  CONSTRAINT teacher_documents_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE messages (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  sender_id CHAR(36) NOT NULL,
  recipient_id CHAR(36) NOT NULL,
  subject TEXT NULL,
  body TEXT NOT NULL,
  read_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL,
  KEY messages_sender_created_idx (sender_id,created_at),
  KEY messages_recipient_created_idx (recipient_id,created_at),
  CONSTRAINT messages_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT messages_sender_fk FOREIGN KEY (sender_id) REFERENCES app_users(id) ON DELETE CASCADE,
  CONSTRAINT messages_recipient_fk FOREIGN KEY (recipient_id) REFERENCES app_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE calendar_events (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  owner_id CHAR(36) NULL,
  title TEXT NOT NULL,
  description TEXT NULL,
  kind VARCHAR(100) NOT NULL DEFAULT 'event',
  starts_at DATETIME(3) NOT NULL,
  ends_at DATETIME(3) NULL,
  audience VARCHAR(100) NOT NULL DEFAULT 'school',
  created_at DATETIME(3) NOT NULL,
  KEY calendar_events_school_starts_idx (school_id,starts_at),
  CONSTRAINT calendar_events_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT calendar_events_owner_fk FOREIGN KEY (owner_id) REFERENCES app_users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE teacher_notifications (
  id CHAR(36) NOT NULL PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  school_id CHAR(36) NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NULL,
  `read` BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME(3) NOT NULL,
  KEY teacher_notifications_user_created_idx (user_id,created_at),
  CONSTRAINT teacher_notifications_user_fk FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE,
  CONSTRAINT teacher_notifications_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE timetable_slots (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  class_id CHAR(36) NOT NULL,
  subject_id CHAR(36) NULL,
  teacher_id CHAR(36) NULL,
  day_of_week SMALLINT NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room TEXT NULL,
  created_at DATETIME(3) NOT NULL,
  KEY timetable_slots_class_idx (class_id),
  KEY timetable_slots_teacher_idx (teacher_id),
  CONSTRAINT timetable_slots_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT timetable_slots_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
  CONSTRAINT timetable_slots_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
  CONSTRAINT timetable_slots_teacher_fk FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL,
  CONSTRAINT timetable_slots_day_ck CHECK (day_of_week BETWEEN 1 AND 7)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE student_bookmarks (
  id CHAR(36) NOT NULL PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  target_type VARCHAR(191) NOT NULL,
  target_id CHAR(36) NOT NULL,
  created_at DATETIME(3) NOT NULL,
  UNIQUE KEY student_bookmarks_target_uq (user_id,target_type,target_id),
  CONSTRAINT student_bookmarks_user_fk FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE fee_structures (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  class_id CHAR(36) NULL,
  name TEXT NOT NULL,
  description TEXT NULL,
  amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  currency VARCHAR(12) NOT NULL DEFAULT 'CDF',
  term TEXT NULL,
  academic_year TEXT NULL,
  due_date DATE NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  KEY idx_fee_structures_school (school_id),
  CONSTRAINT fee_structures_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fee_structures_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE fee_payments (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  fee_structure_id CHAR(36) NULL,
  amount DECIMAL(18,2) NOT NULL DEFAULT 0,
  currency VARCHAR(12) NOT NULL DEFAULT 'CDF',
  method TEXT NULL,
  reference TEXT NULL,
  receipt_no TEXT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'paid',
  paid_at DATETIME(3) NOT NULL,
  note TEXT NULL,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  KEY idx_fee_payments_student (student_id),
  CONSTRAINT fee_payments_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT fee_payments_student_fk FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fee_payments_structure_fk FOREIGN KEY (fee_structure_id) REFERENCES fee_structures(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE teaching_resources (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  teacher_id CHAR(36) NOT NULL,
  class_id CHAR(36) NULL,
  subject_id CHAR(36) NULL,
  academic_year TEXT NULL,
  term TEXT NULL,
  topic TEXT NULL,
  title TEXT NOT NULL,
  description TEXT NULL,
  resource_type VARCHAR(24) NOT NULL DEFAULT 'note',
  storage_path TEXT NULL,
  external_url TEXT NULL,
  file_name TEXT NULL,
  mime_type TEXT NULL,
  size_bytes BIGINT NULL,
  publish_at DATETIME(3) NOT NULL,
  due_date DATETIME(3) NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'published',
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  KEY idx_teaching_resources_school (school_id),
  KEY idx_teaching_resources_class (class_id),
  CONSTRAINT teaching_resources_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT teaching_resources_teacher_fk FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
  CONSTRAINT teaching_resources_class_fk FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
  CONSTRAINT teaching_resources_subject_fk FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
  CONSTRAINT teaching_resources_type_ck CHECK (resource_type IN ('note','presentation','video','video_link','image','reference')),
  CONSTRAINT teaching_resources_status_ck CHECK (status IN ('draft','scheduled','published'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE resource_upload_history (
  id CHAR(36) NOT NULL PRIMARY KEY,
  school_id CHAR(36) NOT NULL,
  resource_id CHAR(36) NULL,
  actor_id CHAR(36) NULL,
  actor_name TEXT NULL,
  action TEXT NOT NULL,
  details JSON NOT NULL,
  created_at DATETIME(3) NOT NULL,
  KEY idx_resource_upload_history_school (school_id,created_at),
  CONSTRAINT resource_upload_history_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE exam_questions (
  id CHAR(36) NOT NULL PRIMARY KEY,
  exam_id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  kind VARCHAR(16) NOT NULL DEFAULT 'mcq',
  prompt TEXT NOT NULL,
  options JSON NOT NULL,
  correct_answer TEXT NULL,
  points DECIMAL(18,2) NOT NULL DEFAULT 1,
  order_index INT NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  KEY idx_exam_questions_exam (exam_id,order_index),
  CONSTRAINT exam_questions_exam_fk FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
  CONSTRAINT exam_questions_school_fk FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  CONSTRAINT exam_questions_kind_ck CHECK (kind IN ('mcq','truefalse','short'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
