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
- Check the assets on this exact release before claiming there is a 409-built downloadable app, SHA-256 checksums, notarization, or an update feed. Source code alone does not establish those properties.

## Credits

Original project © 2026 Yoonsung Ji ([@feelgom](https://github.com/feelgom)) under the [MIT License](LICENSE). 409 TH/ENG adaptation by [Gaparamet](https://github.com/Gaparamet) / 409 Collective. Not affiliated with Apple.
