# Universal Control Helper — 409 Edition (v1.5.5)

A Thai / English adaptation of [feelgom/universal-control-helper](https://github.com/feelgom/universal-control-helper), maintained by [Gaparamet](https://github.com/Gaparamet) (409 Collective).

## What's New in v1.5.5 / มีอะไรใหม่ใน v1.5.5

- 🔒 **แก้ Caps Lock ค้างที่ต้นเหตุ (Source) / Fix stuck Caps Lock at the source:**
  - ระหว่างที่ Universal Control ส่งคีย์บอร์ดข้ามเครื่อง การกด Caps Lock จะเปิด Caps Lock จริงบนเครื่อง Source แล้ว Universal Control คัดลอกสถานะนั้นไปทับบน Target ซ้ำ รุ่นนี้ให้ Source ดับ Caps Lock ของตัวเองทันทีหลังกด (ปิดได้ด้วย `defaults write io.yoonsungji.UniInputFix sourceClearsCapsLock -bool NO`)
  - Target ตรวจสถานะ Caps Lock จากทั้ง IOKit และ Quartz และลดการตั้ง timer ซ้ำซ้อนจาก v1.5.4
  - ผลวัดบน MacBook Air + Mac mini: สลับภาษา 141 ครั้ง ไม่ค้างเลย ช่วงที่ Caps Lock ติดชั่วคราวยาวสุด 137 ms
  - ข้อแลก: ระหว่างเปิด helper จะใช้ Caps Lock แบบกดค้างเพื่อพิมพ์ตัวใหญ่บน Source ไม่ได้
- 🔌 **การเชื่อมต่อทนขึ้น / More robust connection:** TCP keepalive, จัดการสถานะ waiting, timeout ทั้งรอบการเชื่อมต่อและการยืนยันรหัส, ลองใหม่แบบ backoff, และสถานะ "รหัสจับคู่ไม่ตรง" ไม่ถูกเขียนทับอีก
- 🚫 **ปิด Sparkle auto-update ชั่วคราว / Sparkle updater disabled:** feed และ key เดิมเป็นของโปรเจกต์ต้นทาง จึงปิดไว้จนกว่า 409 จะมี feed ของตัวเอง อัปเดตด้วยการดาวน์โหลด ZIP จากหน้า Releases
- 🪟 **หน้าต่าง Settings ไม่เด้งทุกครั้งที่เปิดแอป** (แสดงเฉพาะครั้งแรก หรือเมื่อ Source ยังไม่ได้สิทธิ์ Input Monitoring) และสวิตช์ป้องกัน Caps Lock แสดงเฉพาะในโหมด Target
- ⌨️ **การจับคู่ layout:** เลือก layout อังกฤษแบบ British/U.S. ได้เมื่อไม่มี ABC
- 🧪 **Diagnostics:** เพิ่ม log ผ่าน `os.Logger` (subsystem `co.409.uch`) และตัววัดเสริมที่เปิดด้วย `diagnosticsEnabled` (บันทึกเฉพาะ Caps Lock และ Backspace; ต้องให้สิทธิ์ Input Monitoring บน Target เมื่อเปิดใช้) ชุดทดสอบย้ายไป Swift Testing

### Known limitations / ข้อจำกัดที่ทราบ

- ยังมีช่วงสั้น ๆ (วัดได้ไม่เกิน ~140 ms) หลังกด Caps Lock ที่ Target อาจพิมพ์เป็นตัวพิมพ์ใหญ่
- มีรายงานว่า Backspace บน Target ลบสองตัวเป็นครั้งคราว ยังหาสาเหตุไม่ได้: ในการวัด 227 ครั้ง Target ได้รับปุ่มตรงกับที่กดจริงทุกครั้ง
- แอป sign แบบ ad-hoc: หลังอัปเดตอาจต้องอนุญาต Input Monitoring / Local Network ใหม่
- `scripts/install.sh` ยังชี้ไปที่ release ของโปรเจกต์ต้นทาง อย่าใช้ติดตั้งรุ่น 409

---

# v1.5.4

## What's New in v1.5.4 / มีอะไรใหม่ใน v1.5.4

- 🔒 **Fix Target Mac Caps Lock Stuck / แก้ปัญหา Caps Lock ค้างบนเครื่อง Target:**
  - แก้ไขปัญหาบั๊กที่เมื่อกดสลับภาษาข้ามเครื่องผ่าน Universal Control แล้วสัญญาณ Caps Lock บนเครื่อง Target จะติดค้าง ทำให้พิมพ์ตัวอักษรเป็นพิมพ์ใหญ่ (UPPERCASE) หรือติดตัว Shift ตลอดเวลา
  - เพิ่มโมดูล `CapsLockManager` ควบคุมการปลดล็อก `kIOHIDCapsLockState` อัตโนมัติทันทีที่มีการสลับภาษา พร้อมระบบ Staggered suppression ป้องกันสัญญาณดีเลย์จาก Universal Control
  - เพิ่ม `TargetCapsLockGuard` เฝ้าระวังการเปลี่ยนภาษาบนเครื่อง Target เพื่อดับสถานะ Caps Lock ค้างทันที
  - เพิ่มการตั้งค่า **"ป้องกัน Caps Lock ค้างบน Mac ปลายทาง (Target)"** สามารถเปิด/ปิดได้จากหน้าต่างตั้งค่า

---

# Universal Control Helper — 409 TH/ENG Edition (v1.5.3)

## Features / ฟีเจอร์หลัก

- 🇹🇭 🇬🇧 Thai ↔ English keyboard input source support, including macOS Thai layouts and ABC / U.S.
- ⇪ Physical Caps Lock detection on the Source Mac, with input switching relayed to the Target Mac during Universal Control use.
- 🔄 Supported input-source state synchronization when both Macs run compatible builds.
- 🌐 Settings and menu-bar interface localization in Thai and English.
- 🔗 Bonjour local-network discovery with 6-digit pairing code.
- 🇰🇷 Compatibility path for the upstream Korean 2-set input source.

## Setup / วิธีเริ่มใช้งาน

Install the application on **both Macs**. Enable Universal Control and connect to the same **trusted local network**. Choose Source on the Mac with the physical keyboard and Target on the other Mac, enter the Source's 6-digit pairing code on Target, and allow **Input Monitoring on Source** and **Local Network on both**.

Requires **macOS 13+** and suitable keyboard input sources configured on the Target (e.g., ABC and Thai).

## Important limitations / ข้อควรทราบ

- The pairing code is not end-to-end encryption. **Do not use on untrusted networks.**
- Source requires Input Monitoring permission; Target does not require Input Monitoring for this feature.
- The app's current `scripts/install.sh` still points to **feelgom's upstream release assets**. The Sparkle feed in `Resources/Info.plist` still points upstream too. **Do not present those as 409 download/update channels.** A self-contained 409 distribution requires retargeting, signing/key management, and verification.
- **409 v1.5.3 ZIP release is published:** [Release and assets](https://github.com/Gaparamet/universal-control-helper/releases/tag/v1.5.3). Both ZIP assets are listed by GitHub with SHA-256 `198e69a29092ed2af980d920dd14a74c3a06606ab3f48b662e4ee67fe854e7ed`.
- GitHub Actions CI on main [run #42350880355](https://github.com/Gaparamet/universal-control-helper/actions/runs/42350880355) completed successfully (Test, Build, Verify app bundle). **This does not by itself verify Apple notarization, independent artifact reproducibility, or a functioning 409 Sparkle feed.**

## Credits

Original project © 2026 Yoonsung Ji ([@feelgom](https://github.com/feelgom)) under the [MIT License](LICENSE). 409 TH/ENG adaptation by [Gaparamet](https://github.com/Gaparamet) / 409 Collective. Not affiliated with Apple.
