# AU Agent — Deploy Guide
**Stack:** Railway (backend) + Supabase (DB) + LINE Messaging API

---

## ขั้นตอนที่ 1 — Supabase (Database)

1. ไปที่ https://supabase.com → **New project**
2. ตั้งชื่อ: `au-agent` | เลือก region: **Southeast Asia (Singapore)**
3. รอสัก 2 นาที จนโปรเจคพร้อม
4. ไปที่ **SQL Editor** → วางทั้งหมดจากไฟล์ `database/supabase_schema.sql` → **Run**
5. ไปที่ **Settings → API** คัดลอก:
   - `Project URL` → ใส่ใน `SUPABASE_URL`
   - `service_role` secret → ใส่ใน `SUPABASE_SERVICE_KEY`

---

## ขั้นตอนที่ 2 — LINE Developers (Webhook)

1. ไปที่ https://developers.line.biz → เลือก Channel ที่มีอยู่
2. Tab **Messaging API** → คัดลอก:
   - `Channel access token (long-lived)` → `LINE_CHANNEL_ACCESS_TOKEN`
   - `Channel secret` → `LINE_CHANNEL_SECRET`
3. Webhook URL จะกรอกหลัง deploy Railway เสร็จ (ขั้นตอนที่ 4)
4. เปิด **Use webhook: ON**
5. ปิด Auto-reply messages และ Greeting messages

---

## ขั้นตอนที่ 3 — Railway (Backend)

1. ไปที่ https://railway.app → **New Project → Deploy from GitHub repo**
2. Push folder `backend/` ขึ้น GitHub ก่อน (ถ้ายังไม่มี repo)
3. Railway จะ detect Node.js และ run `node index.js` อัตโนมัติ
4. ไปที่ **Variables** → Add ทั้งหมดนี้:

```
LINE_CHANNEL_ACCESS_TOKEN=xxxxx
LINE_CHANNEL_SECRET=xxxxx
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_KEY=xxxxx
OCR_MODE=demo
FRONTEND_URL=*
PORT=3000
```

5. Railway ให้ URL เช่น `https://au-agent-xxxx.up.railway.app`
6. ทดสอบ: เปิด `https://au-agent-xxxx.up.railway.app/health` → ต้องเห็น `{"ok":true}`

---

## ขั้นตอนที่ 4 — ตั้ง Webhook URL ใน LINE

1. LINE Developers → Messaging API
2. Webhook URL: `https://au-agent-xxxx.up.railway.app/webhook`
3. กด **Verify** → ต้องขึ้น Success

---

## ขั้นตอนที่ 5 — Host Dashboard (ฟรี, ไม่ต้อง install อะไร)

### Netlify Drop (ง่ายที่สุด — ลากวาง)
1. ไปที่ https://app.netlify.com/drop
2. ลาก `planning-mockup.html` ไปวาง
3. ได้ URL ทันที เช่น `https://amazing-biomass-123.netlify.app`

### GitHub Pages
1. Push `planning-mockup.html` ขึ้น GitHub
2. Settings → Pages → branch `main`
3. ได้ `https://username.github.io/repo/planning-mockup.html`

---

## ขั้นตอนที่ 6 — เชื่อม Dashboard กับ Backend

เปิด `planning-mockup.html` หาบรรทัดนี้แล้วแก้:

```javascript
// หาใน <script> แล้วเพิ่มบรรทัดนี้
const API_BASE = 'https://au-agent-xxxx.up.railway.app';
```

---

## ขั้นตอนที่ 7 — ลงทะเบียน LINE Group

ใน LINE group แผนขนส่ง พิมพ์:
```
ลงทะเบียน planning กลุ่มแผน Biomass
```

ใน LINE group คนขับ (ส่งรูปใบชั่ง) พิมพ์:
```
ลงทะเบียน driver_upload กลุ่มคนขับ
```

Bot จะตอบ ✅ ยืนยันการลงทะเบียน

---

## ทดสอบ End-to-End

**1. ทดสอบแผนขนส่ง** — พิมพ์ในกลุ่ม planning:
```
วันที่ 20/06/2026
ต้นทาง: โรงงาน ABC
ปลายทาง: บ.ยางไทย
สินค้า: Wood Pellet
รถ 3 คัน
```
→ Bot ตอบ Flex Message + Dashboard อัปเดต

**2. ทดสอบ OCR** — ส่งรูปใบชั่งในกลุ่ม driver_upload
→ Bot รัน OCR → แจ้งผล → Dashboard แสดงรายการใหม่

**3. Admin verify** — ถ้า confidence ต่ำ → กด verify ใน Dashboard

---

## Future: ย้ายไป SCG Cloud

```bash
# Build Docker image
docker build -t au-agent ./backend

# เปลี่ยน OCR เป็น internal AI
OCR_MODE=internal
INTERNAL_AI_ENDPOINT=https://internal-ai.scg.local/ocr
INTERNAL_AI_KEY=xxxx
```

Database: Export จาก Supabase → Import ใน SCG PostgreSQL

---

## Environment Variables

| Variable | หมายเหตุ |
|---|---|
| `LINE_CHANNEL_ACCESS_TOKEN` | จาก LINE Developers — Required |
| `LINE_CHANNEL_SECRET` | จาก LINE Developers — Required |
| `SUPABASE_URL` | จาก Supabase Settings — Required |
| `SUPABASE_SERVICE_KEY` | service_role key — Required |
| `OCR_MODE` | `demo` / `claude` / `internal` |
| `FRONTEND_URL` | URL dashboard (สำหรับ CORS) |
| `PORT` | 3000 (Railway ตั้งให้อัตโนมัติ) |
| `SMTP_HOST` | smtp.gmail.com (สำหรับส่งเมลสรุป) |
| `SMTP_USER` | อีเมลผู้ส่ง |
| `SMTP_PASS` | App password |
| `EMAIL_TO` | finance@company.com |
