-- ══════════════════════════════════════════════════════════════════
-- AU AGENT — SUPABASE SCHEMA (PostgreSQL)
-- วิธีใช้: Copy ทั้งหมดวางใน Supabase → SQL Editor → Run
-- ══════════════════════════════════════════════════════════════════

-- ─── weight_slips ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS weight_slips (
  id               TEXT PRIMARY KEY,
  slip_type        TEXT NOT NULL CHECK(slip_type IN ('origin','destination')),

  company_name     TEXT,
  company_address  TEXT,
  doc_number       TEXT,

  plate_head       TEXT NOT NULL,
  plate_tail       TEXT,
  vehicle_type     TEXT,

  product_type     TEXT,
  customer         TEXT,
  origin_code      TEXT,
  origin_name      TEXT,
  destination_name TEXT,
  barcode_ref      TEXT,

  weigh_in_date    TEXT,
  weigh_in_time    TEXT,
  weigh_in_kg      REAL,

  weigh_out_date   TEXT,
  weigh_out_time   TEXT,
  weigh_out_kg     REAL,

  net_weight_kg    REAL,

  ocr_confidence   REAL,
  image_url        TEXT,
  has_signature    INTEGER DEFAULT NULL,

  notes            TEXT,
  status           TEXT NOT NULL DEFAULT 'wait',
  received_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── matched_trips ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matched_trips (
  id               TEXT PRIMARY KEY,
  plate            TEXT NOT NULL,
  product_type     TEXT,
  customer         TEXT,

  origin_slip_id   TEXT REFERENCES weight_slips(id),
  dest_slip_id     TEXT REFERENCES weight_slips(id),
  origin_company   TEXT,
  dest_company     TEXT,

  origin_date      TEXT,
  dest_date        TEXT,
  days_gap         INTEGER,

  weight_origin_kg  REAL,
  weight_dest_kg    REAL,
  weight_diff_kg    REAL,
  weight_diff_ton   REAL,

  status           TEXT NOT NULL DEFAULT 'matched',
  matched_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── planning ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS planning (
  id           TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  product_type TEXT,
  origin       TEXT,
  destination  TEXT,
  customer     TEXT,
  ship_date    TEXT,
  truck_count  INTEGER DEFAULT 1,
  status       TEXT DEFAULT 'pending',
  reporter     TEXT,
  line_msg_id  TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ─── group_registry ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS group_registry (
  group_id   TEXT PRIMARY KEY,
  group_name TEXT,
  group_type TEXT CHECK(group_type IN ('planning','driver_upload'))
);

-- ─── admin_users ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_users (
  line_user_id TEXT PRIMARY KEY,
  name         TEXT,
  role         TEXT DEFAULT 'admin'
);

-- ─── line_messages ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS line_messages (
  id          TEXT PRIMARY KEY,
  group_id    TEXT,
  user_id     TEXT,
  msg_type    TEXT,          -- 'text' | 'image'
  content     TEXT,
  slip_id     TEXT REFERENCES weight_slips(id),
  received_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── email_log ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS email_log (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  sent_date  TEXT NOT NULL,
  recipient  TEXT,
  trip_ids   TEXT,
  status     TEXT DEFAULT 'sent',
  sent_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ─── INDEXES ────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_slips_plate   ON weight_slips(plate_head);
CREATE INDEX IF NOT EXISTS idx_slips_status  ON weight_slips(status);
CREATE INDEX IF NOT EXISTS idx_slips_date    ON weight_slips(weigh_in_date);
CREATE INDEX IF NOT EXISTS idx_slips_type    ON weight_slips(slip_type);
CREATE INDEX IF NOT EXISTS idx_trips_plate   ON matched_trips(plate);
CREATE INDEX IF NOT EXISTS idx_trips_date    ON matched_trips(origin_date);
CREATE INDEX IF NOT EXISTS idx_plan_date     ON planning(ship_date);
CREATE INDEX IF NOT EXISTS idx_line_group    ON line_messages(group_id);

-- ─── REALTIME (เปิด live update ให้ dashboard) ──────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE weight_slips;
ALTER PUBLICATION supabase_realtime ADD TABLE matched_trips;
ALTER PUBLICATION supabase_realtime ADD TABLE planning;
ALTER PUBLICATION supabase_realtime ADD TABLE line_messages;

-- ─── ROW LEVEL SECURITY (RLS) ───────────────────────────────────
-- Service role key ที่ backend ใช้ bypass RLS อยู่แล้ว
-- แต่เปิดไว้เพื่อความปลอดภัย
ALTER TABLE weight_slips    ENABLE ROW LEVEL SECURITY;
ALTER TABLE matched_trips   ENABLE ROW LEVEL SECURITY;
ALTER TABLE planning        ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_registry  ENABLE ROW LEVEL SECURITY;
ALTER TABLE line_messages   ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_log       ENABLE ROW LEVEL SECURITY;
