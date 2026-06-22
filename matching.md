# AU Agent — Matching Algorithm

> ไฟล์นี้เป็น **single source of truth** ของเงื่อนไขการจับคู่ทั้งระบบ
> เมื่อเงื่อนไขเปลี่ยน → แก้ที่นี่ก่อน แล้ว implement ตาม

---

## 1. ประเภทใบชั่ง (Slip Type)

| ประเภท | ความหมาย | ระบุอย่างไร |
|--------|----------|------------|
| `origin` | ใบชั่งต้นทาง / Supplier | ใบจากโรงงานที่ส่งสินค้า |
| `destination` | ใบชั่งปลายทาง / Customer | ใบจากโรงงานที่รับสินค้า |

### 1.1 การตรวจ slip_type จาก OCR text

```
ถ้าพบคำ: ปลายทาง | destination | ชั่งปลาย | Receiver | ผู้รับ
  → slip_type = "destination"
ไม่พบ:
  → slip_type = "origin" (default)
```

### 1.2 Override จากรายชื่อบริษัท (company_settings table)

ระบบจะเทียบชื่อบริษัทจาก OCR กับ `company_settings` ทุกครั้งหลัง OCR:

```
สำหรับแต่ละ company ใน company_settings:
  normalize(ocr_company_name) vs normalize(company.name)
  ถ้า score >= company.match_threshold%:
    → override slip_type = company.type (supplier→origin / customer→destination)
    ถ้า company.use_origin_as_dest = true:
      → force slip_type = "destination" แม้ OCR อ่านว่า origin
```

**Normalize function:**
```
lowercase → ลบ บริษัท / จำกัด / จํากัด / co.,ltd / มหาชน → ลบ . - space
```

**Score calculation:**
```
longer  = max(len(a), len(b))
shorter = min(len(a), len(b))
ถ้า longer.includes(shorter) → score = shorter/longer * 100
ไม่เช่นนั้น                  → overlap character score
```

---

## 2. Plate Normalization

ทะเบียนรถ format ต่างกันในแต่ละใบ → normalize ก่อน match

```
normPlate(p) = p.replace(/[-\s]/g, '').toUpperCase()
```

| Input | Normalized |
|-------|-----------|
| `70-9402` | `709402` |
| `70 9402` | `709402` |
| `กข 1234` | `กข1234` |
| `กข-1234` | `กข1234` |

---

## 3. การจับคู่ Origin ↔ Destination (matcher.js)

### เงื่อนไขหลัก

```
Match ได้ เมื่อ:
  1. normPlate(origin.plate_head) === normPlate(dest.plate_head)
  2. dest.weigh_in_date อยู่ใน window [origin.weigh_in_date, origin.weigh_in_date + 48h]
  3. origin.status = 'wait'
  4. dest.status   = 'wait'
```

### Time Window

```
origin → dest:  ใบปลายทางต้องมาหลัง ≤ 48 ชั่วโมง
dest → origin:  ใบต้นทางต้องมาก่อน  ≤ 48 ชั่วโมง
```

> **TODO:** พิจารณาขยาย window เป็น 72h สำหรับเส้นทางไกล

### Algorithm

```
เมื่อรับใบใหม่ (slip_id):
  1. ดึงใบจาก weight_slips
  2. ถ้าเป็น destination → findMatchingOrigin(dest)
     ถ้าเป็น origin       → findMatchingDest(origin)
  3. ถ้าหาคู่ได้ → createMatch(origin, dest)
     ถ้าไม่ได้  → status คง 'wait' รอคู่

findMatchingOrigin(dest):
  query: slip_type='origin', status='wait'
         weigh_in_date ∈ [dest.date - 2d, dest.date]
  filter: normPlate match (ใน JS)
  sort: weigh_in_date DESC, limit 1

findMatchingDest(origin):
  query: slip_type='destination', status='wait'
         weigh_in_date ∈ [origin.date, origin.date + 2d]
  filter: normPlate match (ใน JS)
  sort: weigh_in_date ASC, limit 1
```

### เมื่อ Match สำเร็จ

```
1. INSERT matched_trips (id=M-xxx)
2. UPDATE weight_slips SET status='matched' WHERE id IN (origin.id, dest.id)
3. push LINE message แจ้ง match
```

---

## 4. การจับคู่ แผนขนส่ง ↔ ใบชั่ง (Dashboard UI)

> จับคู่เพื่อแสดงผลใน 3-column comparison view เท่านั้น (ยังไม่ auto-link ใน DB)

### เงื่อนไข

```
plan → origin/dest slip:
  normalize(plan.customer) vs normalize(slip.company_name)
  ถ้า score >= 50% → highlight ใน UI

origin → dest (cross-column):
  normPlate(origin.plate) === normPlate(dest.plate)
```

### Score ที่ใช้ใน UI

```
min threshold = 50% (ต่ำกว่า production เพราะแค่ UI highlight)
```

---

## 5. Dedup Layer (ป้องกันใบซ้ำ)

### Layer 1 — messageId

```
ถ้า line_messages[messageId].content เป็น URL:
  → ใบนี้ process ไปแล้ว → แจ้งซ้ำ + skip
```

### Layer 2 — Content fingerprint

```
ถ้า DB มี weight_slips ที่:
  plate_head = X AND weigh_in_date = Y AND net_weight_kg = Z AND slip_type = T
  → ถือว่าซ้ำ → แจ้ง + skip
```

---

## 6. เงื่อนไขที่ยังไม่ได้ implement (TODO)

- [ ] **Product type matching** — เทียบ product_type ของ origin/dest ก่อน match
- [ ] **Multi-plate** — รถพ่วง มี plate_head + plate_tail ต้องเทียบคู่
- [ ] **Weight tolerance** — net_weight ต่างกัน ≤ X kg ถือว่า match (ลด false positive)
- [ ] **Auto-link plan ↔ slip** — บันทึก plan_id ลง weight_slips เมื่อ match
- [ ] **Plan status auto-update** — ถ้า matched_trip ครบตาม truck_count → plan = 'completed'

---

## 7. ตาราง DB ที่เกี่ยวข้อง

| ตาราง | สิ่งที่เก็บ |
|-------|-----------|
| `weight_slips` | ใบชั่งทุกใบ — slip_type, plate_head, status |
| `matched_trips` | คู่ที่ match แล้ว — origin_slip_id, dest_slip_id |
| `planning` | แผนขนส่ง — destination, customer, truck_count |
| `company_settings` | Supplier/Customer list — name, type, match_threshold, use_origin_as_dest |

---

## 8. Log Keywords (Render logs)

| Keyword | ความหมาย |
|---------|---------|
| `[CLASSIFY]` | company_settings override slip_type |
| `[OCR_WEIGHT_LINES]` | debug น้ำหนักที่ regex กำลังดู |
| `[OCR] Signature detected` | พบลายเซ็นจาก text pattern |
| `[OCR] No signature` | ไม่พบลายเซ็น |
| `[OCR] Duplicate slip` | Layer 2 dedup trigger |
| `[PLAN_SELECT] error` | confirm_plan query ล้มเหลว |
| `[PLANNING] Insert error` | บันทึกแผนล้มเหลว |

---

*อัปเดตล่าสุด: 2026-06-22*
