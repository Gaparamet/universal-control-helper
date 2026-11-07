# Universal Control Helper — 409 TH/ENG Edition (v1.5.3)

A Thai / English adaptation of [feelgom/universal-control-helper](https://github.com/feelgom/universal-control-helper), maintained in the [409 repository](https://github.com/Gaparamet/universal-control-helper).

## What's included / มีอะไรใหม่

- 🇹🇭 Thai ↔ English keyboard input source support, including macOS Thai layouts and ABC / U.S.
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
