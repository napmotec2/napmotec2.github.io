-- ══════════════════════════════════════════════════
-- AU AGENT — MATCHING ENGINE
-- Logic: plate_head ตรงกัน + ปลายทางห่างจากต้นทาง ≤ 48 ชม.
-- ══════════════════════════════════════════════════

-- STEP 1: หาคู่ที่ match ได้
-- ─────────────────────────────────────────────────
SELECT
  'PREVIEW คู่ที่จับได้:' AS label,
  o.id            AS origin_id,
  d.id            AS dest_id,
  o.plate_head    AS plate,
  o.product_type,
  o.company_name  AS origin_company,
  d.company_name  AS dest_company,
  o.weigh_out_date AS origin_date,
  d.weigh_out_date AS dest_date,
  (julianday(d.weigh_in_date) - julianday(o.weigh_in_date)) AS days_gap,
  o.net_weight_kg AS weight_origin_kg,
  o.net_weight_ton AS weight_origin_ton,
  d.net_weight_kg  AS weight_dest_kg,
  d.net_weight_ton AS weight_dest_ton,
  ROUND(d.net_weight_kg - o.net_weight_kg, 0) AS diff_kg,
  ROUND(d.net_weight_ton - o.net_weight_ton, 3) AS diff_ton
FROM weight_slips o
JOIN weight_slips d
  ON  o.plate_head = d.plate_head
  AND o.slip_type  = 'origin'
  AND d.slip_type  = 'destination'
  AND o.status     = 'wait'
  AND d.status     = 'wait'
  AND (julianday(d.weigh_in_date) - julianday(o.weigh_in_date)) BETWEEN 0 AND 2;


-- STEP 2: INSERT ลง matched_trips
-- ─────────────────────────────────────────────────
INSERT INTO matched_trips (
  id, plate, product_type, customer,
  origin_slip_id, dest_slip_id,
  origin_company, dest_company,
  origin_date, dest_date, days_gap,
  weight_origin_kg, weight_dest_kg,
  weight_diff_kg, weight_diff_ton
)
SELECT
  'M-' || printf('%03d', ROW_NUMBER() OVER (ORDER BY o.id)),
  o.plate_head,
  o.product_type,
  COALESCE(d.customer, o.customer),
  o.id, d.id,
  o.company_name, d.company_name,
  o.weigh_out_date, d.weigh_out_date,
  CAST(julianday(d.weigh_in_date) - julianday(o.weigh_in_date) AS INTEGER),
  o.net_weight_kg, d.net_weight_kg,
  ROUND(d.net_weight_kg - o.net_weight_kg, 0),
  ROUND(d.net_weight_ton - o.net_weight_ton, 3)
FROM weight_slips o
JOIN weight_slips d
  ON  o.plate_head = d.plate_head
  AND o.slip_type  = 'origin'
  AND d.slip_type  = 'destination'
  AND o.status     = 'wait'
  AND d.status     = 'wait'
  AND (julianday(d.weigh_in_date) - julianday(o.weigh_in_date)) BETWEEN 0 AND 2;


-- STEP 3: อัปเดต status ใบที่ match แล้ว → 'matched'
-- ─────────────────────────────────────────────────
UPDATE weight_slips
SET status = 'matched'
WHERE id IN (
  SELECT origin_slip_id FROM matched_trips
  UNION ALL
  SELECT dest_slip_id   FROM matched_trips
);


-- STEP 4: ดูผลลัพธ์สุดท้าย
-- ─────────────────────────────────────────────────

-- สรุปสถานะใบทั้งหมด
SELECT
  '── STATUS SUMMARY ──' AS section,
  status,
  COUNT(*) AS count
FROM weight_slips
GROUP BY status
ORDER BY
  CASE status
    WHEN 'matched' THEN 1
    WHEN 'wait'    THEN 2
    WHEN 'verify'  THEN 3
    WHEN 'fail'    THEN 4
  END;

-- matched_trips ทั้งหมด
SELECT
  '── MATCHED TRIPS ──' AS section,
  id, plate, product_type, customer,
  origin_company, dest_company,
  origin_date, dest_date, days_gap,
  weight_origin_kg, weight_dest_kg,
  weight_diff_kg, weight_diff_ton
FROM matched_trips;

-- ใบที่ยังรอ
SELECT '── ยังรอจับคู่ (wait) ──' AS section, id, slip_type, plate_head, weigh_in_date, net_weight_kg
FROM weight_slips WHERE status = 'wait';

-- ใบที่รอ verify
SELECT '── รอยืนยัน (verify) ──' AS section, id, plate_head, ocr_confidence, notes
FROM weight_slips WHERE status = 'verify';

-- ใบที่ fail
SELECT '── OCR ล้มเหลว (fail) ──' AS section, id, plate_head, ocr_confidence, notes
FROM weight_slips WHERE status = 'fail';
