-- ══════════════════════════════════════════════════
-- AU AGENT — DATABASE SCHEMA
-- รองรับใบชั่งน้ำหนักจริง (ต้นทาง + ปลายทาง)
-- ══════════════════════════════════════════════════

-- ─── weight_slips ───────────────────────────────
-- เก็บใบชั่งทุกใบที่รับเข้ามา (ทั้งต้นทางและปลายทาง)
-- สถานะ status:
--   'wait'    = รอจับคู่  (รับใบแล้ว แต่ยังไม่มีใบคู่)
--   'verify'  = รอยืนยัน (OCR confidence 40–69% ต้องให้ admin ตรวจ)
--   'fail'    = OCR ล้มเหลว (confidence <40% หรืออ่านไม่ออก)
--   'matched' = จับคู่สำเร็จแล้ว
-- ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS weight_slips (
  id               TEXT PRIMARY KEY,          -- O-001, D-001 ...
  slip_type        TEXT NOT NULL              -- 'origin' | 'destination'
                   CHECK(slip_type IN ('origin','destination')),

  -- ข้อมูลหัวใบ
  company_name     TEXT,                      -- บริษัทผู้ชั่ง
  company_address  TEXT,
  doc_number       TEXT,                      -- เลขที่เอกสาร / ลำดับที่

  -- ทะเบียนรถ
  plate_head       TEXT NOT NULL,             -- ทะเบียนหัว (primary match key)
  plate_tail       TEXT,                      -- ทะเบียนท้าย (optional)
  vehicle_type     TEXT,                      -- เช่น รถพ่วงตั้ม

  -- สินค้า / ลูกค้า
  product_type     TEXT,                      -- ไม้สับ, Wood Pellet ...
  customer         TEXT,                      -- ชื่อลูกค้า/บริษัทผู้ส่ง
  origin_code      TEXT,                      -- รหัสโรงงานต้นทาง (เช่น A003)
  origin_name      TEXT,                      -- ชื่อโรงงานต้นทาง
  destination_name TEXT,                      -- ชื่อโรงงานปลายทาง
  barcode_ref      TEXT,                      -- เลข Barcode อ้างอิง

  -- ชั่งเข้า
  weigh_in_date    TEXT,                      -- YYYY-MM-DD
  weigh_in_time    TEXT,                      -- HH:MM:SS
  weigh_in_kg      REAL,

  -- ชั่งออก
  weigh_out_date   TEXT,
  weigh_out_time   TEXT,
  weigh_out_kg     REAL,

  -- สุทธิ
  net_weight_kg    REAL,
  net_weight_ton   REAL
                   GENERATED ALWAYS AS (ROUND(net_weight_kg / 1000.0, 3))
                   VIRTUAL,

  -- OCR
  ocr_confidence   REAL,                      -- 0.0 – 100.0
  image_url        TEXT,                      -- Google Drive link
  has_signature    INTEGER DEFAULT NULL,      -- 1=SIGNED, 0=UNSIGNED, NULL=ยังไม่ตรวจ

  notes            TEXT,
  status           TEXT NOT NULL DEFAULT 'wait',
  received_at      TEXT NOT NULL DEFAULT (datetime('now','localtime'))
);

-- ─── matched_trips ──────────────────────────────
-- เก็บคู่ที่จับได้สำเร็จ (1 row = 1 trip ที่ครบทั้งต้นทาง+ปลายทาง)
-- ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matched_trips (
  id               TEXT PRIMARY KEY,          -- M-001, M-002 ...
  plate            TEXT NOT NULL,
  product_type     TEXT,
  customer         TEXT,

  origin_slip_id   TEXT REFERENCES weight_slips(id),
  dest_slip_id     TEXT REFERENCES weight_slips(id),
  origin_company   TEXT,
  dest_company     TEXT,

  origin_date      TEXT,
  dest_date        TEXT,
  days_gap         INTEGER,                   -- ต่างกันกี่วัน

  weight_origin_kg  REAL,
  weight_dest_kg    REAL,
  weight_diff_kg    REAL,                     -- ปลายทาง - ต้นทาง (ติดลบ = น้ำหนักหาย)
  weight_diff_ton   REAL,

  status           TEXT NOT NULL DEFAULT 'matched',
  matched_at       TEXT NOT NULL DEFAULT (datetime('now','localtime'))
);

-- ─── planning ────────────────────────────────────
CREATE TABLE IF NOT EXISTS planning (
  id           TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(4)))),
  product_type TEXT,
  origin       TEXT,
  destination  TEXT,
  customer     TEXT,
  ship_date    TEXT,                          -- YYYY-MM-DD
  truck_count  INTEGER DEFAULT 1,
  status       TEXT DEFAULT 'pending',        -- pending / confirmed / rescheduled / cancelled
  reporter     TEXT,
  line_msg_id  TEXT,                          -- LINE message ID อ้างอิง
  created_at   TEXT DEFAULT (datetime('now','localtime'))
);

-- ─── group_registry ─────────────────────────────
CREATE TABLE IF NOT EXISTS group_registry (
  group_id   TEXT PRIMARY KEY,
  group_name TEXT,
  group_type TEXT CHECK(group_type IN ('planning','driver_upload'))
);

-- ─── admin_users ────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_users (
  line_user_id TEXT PRIMARY KEY,
  name         TEXT,
  role         TEXT DEFAULT 'admin'
);

-- ─── email_log ───────────────────────────────────
-- เก็บประวัติการส่งเมลสรุปประจำวัน
CREATE TABLE IF NOT EXISTS email_log (
  id           TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(4)))),
  sent_date    TEXT NOT NULL,                 -- วันที่ส่ง (YYYY-MM-DD)
  recipient    TEXT,
  trip_ids     TEXT,                          -- JSON array ของ matched_trip IDs
  status       TEXT DEFAULT 'sent',           -- sent | failed
  sent_at      TEXT DEFAULT (datetime('now','localtime'))
);

-- ─── INDEXES ─────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_slips_plate     ON weight_slips(plate_head);
CREATE INDEX IF NOT EXISTS idx_slips_status    ON weight_slips(status);
CREATE INDEX IF NOT EXISTS idx_slips_date      ON weight_slips(weigh_in_date);
CREATE INDEX IF NOT EXISTS idx_slips_type      ON weight_slips(slip_type);
CREATE INDEX IF NOT EXISTS idx_trips_plate     ON matched_trips(plate);
CREATE INDEX IF NOT EXISTS idx_planning_date   ON planning(ship_date);
CREATE INDEX IF NOT EXISTS idx_planning_status ON planning(status);
