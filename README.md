<p align="center">
  <img src=".github/assets/hero.svg" alt="Universal Control Helper — 409 TH/ENG Edition: Caps Lock sync between Macs" width="100%" />
</p>

<h1 align="center">Universal Control Helper · 409 TH/ENG Edition</h1>

<p align="center">
  <strong>กด Caps Lock บน MacBook แล้วสลับภาษาไทย / อังกฤษบน Mac mini ได้อีกครั้ง</strong><br />
  <sub>Keep Thai / English input sources in sync across Macs using Apple Universal Control.</sub>
</p>

<p align="center">
  <a href="https://github.com/Gaparamet/universal-control-helper/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Gaparamet/universal-control-helper/ci.yml?branch=main&style=flat-square&label=CI"></a>
  <a href="https://github.com/Gaparamet/universal-control-helper/releases"><img alt="Releases" src="https://img.shields.io/badge/Releases-409%20Edition-7c3aed?style=flat-square"></a>
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/License-MIT-31c48d?style=flat-square"></a>
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-111827?style=flat-square&logo=apple">
</p>

> [!IMPORTANT]
> **409 TH/ENG Edition** เป็นการดัดแปลงจาก [Universal Control Helper โดย feelgom](https://github.com/feelgom/universal-control-helper) เพื่อรองรับการใช้งาน **Thai ↔ English** และ UI ภาษาไทย/อังกฤษ ขอบคุณ [@feelgom](https://github.com/feelgom) สำหรับต้นฉบับโอเพนซอร์สภายใต้ [MIT License](LICENSE) (สงวนประกาศลิขสิทธิ์เดิม)
>
> **409 Release available:** [v1.5.3 — TH/ENG Edition](https://github.com/Gaparamet/universal-control-helper/releases/tag/v1.5.3) เผยแพร่ ZIP สำหรับ **macOS Apple Silicon (arm64)** แล้ว พร้อม SHA-256 บนหน้า Release ส่วนการอัปเดตผ่าน Sparkle และ `scripts/install.sh` ยังชี้ไปที่โปรเจกต์ต้นฉบับ (อ่านข้อควรระวังด้านล่าง)

## 🇹🇭 ทำไมต้องมีตัวนี้?

ถ้าใช้ **Universal Control** ลากเคอร์เซอร์และคีย์บอร์ดจาก MacBook ไปยัง Mac mini บางครั้งการกด **Caps Lock เพื่อสลับภาษา** จะไม่ทำงานบนเครื่องปลายทาง และกลายเป็นการเปิด/ปิด Caps Lock แทน

Universal Control Helper ตรวจจับการกด Caps Lock จาก **คีย์บอร์ดจริงบน Source Mac** แล้วส่งสัญญาณไปให้ **Target Mac** เปลี่ยน Input Source ผ่านเครือข่ายภายใน พร้อมซิงค์สถานะภาษาเมื่อมีการเปลี่ยน Input Source บน Source

```text
MacBook / Source                   Mac mini / Target
Physical Caps Lock ── Bonjour / LAN ──▶ Thai ↔ ABC
     TH / ENG state ────────────────▶ sync language
```

### ความสามารถ

- 🇹🇭 **Thai / English:** รองรับ Thai (รวม Kedmanee / Pattachote ที่ macOS ระบุเป็น Thai) และ ABC / U.S.
- ⇪ **Physical Caps Lock relay:** ส่งเหตุการณ์กด Caps Lock จาก Source ไป Target แทนการรอให้ Universal Control ส่งปุ่มนั้น
- 🔄 **Input source synchronization:** ซิงค์สถานะภาษาจาก Source ไป Target เมื่อทั้งสองฝั่งใช้รุ่นที่รองรับ
- 🌐 **Thai / English UI:** เลือกภาษาหน้าต่าง Settings และ Menu Bar ได้
- 🔗 **Local pairing:** ค้นหาผ่าน Bonjour และจับคู่ด้วยรหัส 6 หลัก
- 🇰🇷 ยังคงรองรับ Korean 2-set จากโปรเจกต์ต้นทางเมื่อมี Input Source ที่เหมาะสม

## ติดตั้งรุ่น 409

### ดาวน์โหลด v1.5.3 (409 TH/ENG Edition)

**สำหรับ Mac ชิป Apple Silicon (M1 / M2 / M3 / M4)** ดาวน์โหลดจาก [409 GitHub Release v1.5.3](https://github.com/Gaparamet/universal-control-helper/releases/tag/v1.5.3):

- [UniversalControlHelper-1.5.3-TH-ENG.zip](https://github.com/Gaparamet/universal-control-helper/releases/download/v1.5.3/UniversalControlHelper-1.5.3-TH-ENG.zip) — ไฟล์หลัก
- [UniversalControlHelper-v1.5.3-macOS-arm64.zip](https://github.com/Gaparamet/universal-control-helper/releases/download/v1.5.3/UniversalControlHelper-v1.5.3-macOS-arm64.zip) — ชื่อไฟล์สำรอง (GitHub รายงาน SHA-256 ตรงกัน)

ดาวน์โหลดและแตก ZIP แล้วลาก `Universal Control Helper.app` ไปที่ `/Applications` ทั้ง **MacBook (Source)** และ **Mac mini (Target)** จากนั้นเปิดแอปเพื่อตั้งค่าตามด้านล่าง

**SHA-256 (ทั้งสอง ZIP ตามข้อมูล GitHub Release):**

```text
198e69a29092ed2af980d920dd14a74c3a06606ab3f48b662e4ee67fe854e7ed
```

ตรวจไฟล์ที่ดาวน์โหลดบน Mac:

```bash
shasum -a 256 ~/Downloads/UniversalControlHelper-1.5.3-TH-ENG.zip
```

> [!NOTE]
> ไฟล์ Release นี้ประกาศเป็นรุ่น **arm64 / Apple Silicon**; ยังไม่มีหลักฐานว่า ZIP ดังกล่าวรองรับ Mac Intel หรือผ่าน Apple Notarization หาก macOS แจ้งเตือนความปลอดภัย ให้ตรวจแหล่งดาวน์โหลดและไฟล์ก่อนอนุญาตเปิดแอป

### สำหรับนักพัฒนา: Build จาก Source

ต้องใช้ macOS 13+ และเครื่องมือ Xcode / Swift สำหรับ Build แอป macOS

```bash
git clone https://github.com/Gaparamet/universal-control-helper.git
cd universal-control-helper

swift test -Xswiftc -warnings-as-errors
BUILD_UNIVERSAL=1 ./scripts/build-app.sh
./scripts/verify-release.sh
open "dist/Universal Control Helper.app"
```

เมื่อทดสอบเรียบร้อย สามารถย้าย `dist/Universal Control Helper.app` ไปยัง `/Applications` ด้วย Finder ได้ แอปที่ Build เองอาจใช้การลงนามแบบ ad-hoc และยังไม่ใช่แอปที่ Apple notarize

**ต้องการไฟล์แอปสำหรับ Apple Silicon?** ใช้ ZIP ของ [409 Release v1.5.3](https://github.com/Gaparamet/universal-control-helper/releases/tag/v1.5.3) ด้านบน ส่วนการ Build จาก Source เป็นทางเลือกสำหรับนักพัฒนา

> [!WARNING]
> **ดาวน์โหลดรุ่น 409 จาก Release ZIP โดยตรง** — ตัวติดตั้ง `scripts/install.sh` ใน Source ปัจจุบันยังดาวน์โหลดไฟล์จาก `feelgom/universal-control-helper` (ต้นฉบับ) และ `Resources/Info.plist` ยังตั้งค่า Sparkle Update Feed ของต้นฉบับอยู่ โปรดอย่าใช้สองช่องทางนั้นเพื่อดาวน์โหลด/อัปเดต 409 Edition จนกว่าจะปรับและทดสอบแยกต่างหาก

### ตั้งค่าบน Mac ทั้งสองเครื่อง

1. เปิด **Universal Control** บน Mac ทั้งสอง และให้เครื่องอยู่ใน Local Network ที่เชื่อถือได้เดียวกัน
2. เปิดแอปทั้งสองเครื่อง แล้วเลือก **Source** บน MacBook ที่ต่อคีย์บอร์ดจริง และ **Target** บน Mac mini
3. นำ **Pairing Code 6 หลัก** จาก Source ไปกรอกที่ Target
4. อนุญาต **Input Monitoring** บน Source Mac และ **Local Network** บนทั้งสองเครื่องตามที่ macOS ขอ (Target ไม่ต้องใช้ Input Monitoring สำหรับฟังก์ชันนี้)
5. เปิด Input Source ที่ต้องการบน Target เช่น **ABC** และ **Thai** ใน System Settings → Keyboard → Text Input
6. ย้ายเคอร์เซอร์ผ่าน Universal Control ไปยัง Target และลองกด Caps Lock

> ถ้าต้องการสลับภาษาชั่วคราวโดยยังไม่ติดตั้งแอป ให้ใช้ `Control + Space` ตาม Shortcut ที่ตั้งค่าไว้บน Mac ปลายทาง

### Troubleshooting

| อาการ | สิ่งที่ควรตรวจ |
| --- | --- |
| Caps Lock ยังไม่เปลี่ยนภาษา | Source ได้รับสิทธิ์ Input Monitoring จริงหรือไม่; ลองเปิด Settings และตรวจ Permission |
| เชื่อมต่อไม่ติด | ทั้งสองเครื่องอยู่ LAN เดียวกัน, แอปเปิดอยู่, Pairing Code ตรงกัน และอนุญาต Local Network แล้ว |
| ภาษาไม่ซิงค์ | Target มี Input Source ที่ต้องการ (ABC และ Thai) ติดตั้งและเปิดใช้งานอยู่หรือไม่ |
| `zsh: permission denied: install.sh` | Shell script อาจยังไม่มี execute bit; ควรอ่าน Script ให้เข้าใจก่อนรันผ่าน `bash path/to/install.sh` — และโปรดทราบว่า Installer ปัจจุบันยังชี้ Upstream ไม่ใช่ 409 |
| อัปเดตแล้ว Permission หาย | บิลด์แบบ ad-hoc อาจต้องให้สิทธิ์ Input Monitoring ใหม่; ตรวจใน System Settings → Privacy & Security |

## ความเป็นส่วนตัวและเครือข่าย

แอปออกแบบให้ส่งเฉพาะสัญญาณสลับภาษาและสถานะ Input Source ที่รองรับ ไม่ได้ออกแบบให้ส่งข้อความที่พิมพ์ คลิปบอร์ด หรือเมาส์ผ่าน Relay ของแอป อย่างไรก็ตาม **Source ต้องได้รับสิทธิ์ Input Monitoring** เพื่อดูเหตุการณ์ของคีย์บอร์ดจริง

**รหัสจับคู่ไม่ใช่ระบบเข้ารหัสการสื่อสาร** จึงควรใช้เฉพาะ LAN ที่เชื่อถือได้ ไม่ควรใช้บนเครือข่ายสาธารณะหรือเครือข่ายที่ไม่ไว้วางใจ

## For English readers

**Universal Control Helper — 409 TH/ENG Edition** is a macOS menu-bar utility adapted from [feelgom's open-source project](https://github.com/feelgom/universal-control-helper). It relays physical Caps Lock presses and supported keyboard-input-source state from a **Source Mac** to a **Target Mac** over a trusted local network. The 409 adaptation adds Thai / English input source support and Thai / English interface localization while retaining the upstream Korean path.

**Requirements:** macOS 13+, the app installed on both Macs, Universal Control enabled, a shared trusted LAN, Source Input Monitoring permission, and matching 6-digit pairing codes. Both Macs need relevant input sources configured. This is **not an Apple product** and is not affiliated with or endorsed by Apple.

**Binary status:** 409 v1.5.3 arm64 ZIPs are now available from the [409 release page](https://github.com/Gaparamet/universal-control-helper/releases/tag/v1.5.3), with SHA-256 published there. The checked-in installer and Sparkle update URL still reference the original upstream project; **do not use them as 409 download/update channels**. Notarization has not been verified here.

## Development & attribution

```bash
swift test -Xswiftc -warnings-as-errors
BUILD_UNIVERSAL=1 ./scripts/build-app.sh
REQUIRE_UNIVERSAL=1 ./scripts/verify-release.sh
```

- [Release notes](RELEASE_NOTES.md) · [Release workflow](RELEASING.md) · [409 releases](https://github.com/Gaparamet/universal-control-helper/releases)
- [Report a bug / request a feature](https://github.com/Gaparamet/universal-control-helper/issues) · [Security policy](SECURITY.md)
- Original project: [feelgom/universal-control-helper](https://github.com/feelgom/universal-control-helper), © 2026 Yoonsung Ji, licensed under [MIT](LICENSE).
- 409 TH/ENG adaptation: [Gaparamet](https://github.com/Gaparamet) / 409 Collective.

---

<p align="center"><sub>Made for two Macs, one keyboard, and a Caps Lock key that refused to cooperate. 💜 · 409 Collective</sub></p>
