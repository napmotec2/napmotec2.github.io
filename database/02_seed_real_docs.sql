-- ══════════════════════════════════════════════════
-- AU AGENT — SEED DATA จากใบจริง 4 ใบ
-- ══════════════════════════════════════════════════
-- สถานะเริ่มต้น:
--   ใบต้นทาง  → status = 'wait'    (รอจับคู่ = รอใบปลายทาง)
--   ใบปลายทาง → status = 'wait'    (รอจับคู่ = รอใบต้นทาง)
--   ถ้า OCR confidence 40-69% → status = 'verify'
--   ถ้า OCR confidence <40%   → status = 'fail'
-- ══════════════════════════════════════════════════

-- ─── ใบต้นทาง O-001 ─────────────────────────────
-- บ.เอบีซี จำกัด | ทะเบียน 11-2234 | 11/06/2026
INSERT INTO weight_slips (
  id, slip_type,
  company_name, company_address, doc_number,
  plate_head, plate_tail, vehicle_type,
  product_type, customer,
  origin_name, destination_name,
  weigh_in_date,  weigh_in_time,  weigh_in_kg,
  weigh_out_date, weigh_out_time, weigh_out_kg,
  net_weight_kg,
  ocr_confidence, notes, status
) VALUES (
  'O-001', 'origin',
  'บริษัท เอบีซี จำกัด',
  '12/3 หมู่ที่ 4 ต.ไม้ยาง อ.สองสาม กทม. 12345',
  '00001',
  '11-2234', NULL, NULL,
  'ไม้สับ (Wood Chips)', 'Biomass',
  'บริษัท เอบีซี จำกัด', NULL,
  '2026-06-11', '11:12:00', 19020,
  '2026-06-11', '11:48:00', 49660,
  30640,
  92.0, NULL, 'wait'
);

-- ─── ใบต้นทาง O-002 ─────────────────────────────
-- วู้ดพาเลทแดนมังกร | ทะเบียน 82-8250 | 10/06/2026
INSERT INTO weight_slips (
  id, slip_type,
  company_name, company_address, doc_number,
  plate_head, plate_tail, vehicle_type,
  product_type, customer,
  origin_name, destination_name,
  weigh_in_date,  weigh_in_time,  weigh_in_kg,
  weigh_out_date, weigh_out_time, weigh_out_kg,
  net_weight_kg,
  ocr_confidence, notes, status
) VALUES (
  'O-002', 'origin',
  'บริษัท วู้ดพาเลทแดนมังกร จำกัด',
  '97 ปลวกแดง ถ.ระยอง อ.เมือง (สาขาย่อย) 20450',
  '260612',
  '82-8250', NULL, 'รถพ่วงตั้ม',
  'Wood Pellet', 'Biomass',
  'บริษัท วู้ดพาเลทแดนมังกร จำกัด', NULL,
  '2026-06-10', '13:45:08', 20380,
  '2026-06-10', '14:05:08', 50815,
  30435,
  88.0, NULL, 'wait'
);

-- ─── ใบปลายทาง D-001 ────────────────────────────
-- บ.ยางไทย จำกัด | ทะเบียน 11-2234 (หัว) + 11-2235 (ท้าย) | 12/06/2026
INSERT INTO weight_slips (
  id, slip_type,
  company_name, doc_number,
  plate_head, plate_tail, vehicle_type,
  product_type, customer,
  origin_code, origin_name, barcode_ref,
  weigh_in_date,  weigh_in_time,  weigh_in_kg,
  weigh_out_date, weigh_out_time, weigh_out_kg,
  net_weight_kg,
  ocr_confidence,
  notes, status
) VALUES (
  'D-001', 'destination',
  'บริษัท ยางไทย จำกัด', 'NN30015',
  '11-2234', '11-2235', NULL,
  'ไม้ยางพาราสับ', 'บริษัท ยางไทย จำกัด',
  'A003', 'บ.ยางไทย จำกัด (มหาชน)-สมุทรสาคร', 'A0010',
  '2026-06-12', '10:47:12', 49610,
  '2026-06-12', '11:58:05', 19290,
  30320,
  90.0,
  'ไม้ยางพาราสับ ยางไทย=30640KG.', 'wait'
);

-- ─── ใบปลายทาง D-002 ────────────────────────────
-- บจ.ทีเค (ไทย) เทรดดิ้ง | ทะเบียน 82-8250 | 11/06/2026
INSERT INTO weight_slips (
  id, slip_type,
  company_name, company_address, doc_number,
  plate_head, plate_tail, vehicle_type,
  product_type, customer,
  weigh_in_date,  weigh_in_time,  weigh_in_kg,
  weigh_out_date, weigh_out_time, weigh_out_kg,
  net_weight_kg,
  ocr_confidence, notes, status
) VALUES (
  'D-002', 'destination',
  'บจ. ทีเค (ไทย) เทรดดิ้ง',
  '332 ถ.นิคมอุตสาหกรรม ประตู 2 จ.ปทุมธานี อ.ทุ่งยั้ง',
  'OKW260522-22',
  '82-8250', NULL, NULL,
  'Wood Pellet', 'ไปโอแมสจำกัด (Biomass)',
  '2026-06-11', '09:20:13', 50580,
  '2026-06-11', '11:30:41', 20210,
  30370,
  85.0, NULL, 'wait'
);

-- ─── ตัวอย่างใบที่ OCR อ่านไม่ชัด (verify) ──────
INSERT INTO weight_slips (
  id, slip_type,
  company_name, doc_number,
  plate_head,
  product_type, customer,
  weigh_in_date, weigh_in_time, weigh_in_kg,
  weigh_out_date, weigh_out_time, weigh_out_kg,
  net_weight_kg,
  ocr_confidence, notes, status
) VALUES (
  'O-003', 'origin',
  'โรงงาน ก.', 'XXX-001',
  'อ?-12?4',   -- ทะเบียนอ่านไม่ชัด
  'ไม้สับ', NULL,
  '2026-06-13', '08:30:00', 18500,
  '2026-06-13', '09:10:00', 49000,
  30500,
  58.0,        -- confidence 58% → verify
  'ทะเบียนเบลอ ตัวเลขไม่ชัดเจน',
  'verify'     -- รอ admin ตรวจสอบ
);

-- ─── ตัวอย่างใบที่ OCR fail ──────────────────────
INSERT INTO weight_slips (
  id, slip_type,
  company_name, doc_number,
  plate_head,
  product_type,
  weigh_in_date, weigh_in_kg,
  weigh_out_date, weigh_out_kg,
  net_weight_kg,
  ocr_confidence, notes, status
) VALUES (
  'O-004', 'origin',
  NULL, NULL,
  '???-???',   -- อ่านไม่ออกเลย
  NULL,
  '2026-06-13', NULL,
  '2026-06-13', NULL,
  NULL,
  18.0,        -- confidence 18% → fail
  'รูปเบลอมาก ถ่ายไกล อ่านไม่ออก',
  'fail'       -- ต้องกรอกเอง
);
