import Foundation

public enum ConnectionStatus: Equatable, Sendable {
    case starting
    case off
    case permissionRequired
    case searchingTarget
    case searchError(String)
    case connectingTarget
    case authenticating
    case connectionError(String)
    case connectedSyncing
    case invalidResponse
    case sendError(String)
    case disconnectedSearching
    case readyWaitingForSource
    case listenError(String)
    case sourceConnectedAwaitingAuth
    case pairingCodeMismatch
    case reconnectingWithNewCode
    case blockedUnauthenticated
    case blockedInvalidData
    case disconnectedWaiting
    case reallowInputMonitoring
    case custom(String)

    public var isConnected: Bool {
        self == .connectedSyncing
    }

    public var isError: Bool {
        switch self {
        case .permissionRequired, .searchError, .connectionError,
             .invalidResponse, .sendError, .listenError,
             .pairingCodeMismatch, .blockedUnauthenticated, .blockedInvalidData:
            return true
        default:
            return false
        }
    }

    public func localized(for language: AppLanguage) -> String {
        switch language {
        case .th:
            switch self {
            case .starting:
                return "กำลังเริ่มต้น…"
            case .off:
                return "ปิดใช้งาน"
            case .permissionRequired:
                return "ต้องการสิทธิ์การตรวจสอบการป้อนข้อมูล (Input Monitoring)"
            case .searchingTarget:
                return "กำลังค้นหา Mac ปลายทาง (Target)…"
            case .searchError(let err):
                return "ค้นหาล้มเหลว: \(err)"
            case .connectingTarget:
                return "กำลังเชื่อมต่อกับ Mac ปลายทาง…"
            case .authenticating:
                return "กำลังยืนยันรหัสจับคู่…"
            case .connectionError(let err):
                return "เชื่อมต่อล้มเหลว: \(err)"
            case .connectedSyncing:
                return "เชื่อมต่อแล้ว · ซิงค์แป้นพิมพ์ (TH/ENG)"
            case .invalidResponse:
                return "การตอบกลับไม่ถูกต้อง"
            case .sendError(let err):
                return "ส่งข้อมูลล้มเหลว: \(err)"
            case .disconnectedSearching:
                return "การเชื่อมต่อขาดหาย · กำลังค้นหาใหม่…"
            case .readyWaitingForSource:
                return "พร้อมทำงาน · รอการเชื่อมต่อจาก Mac ต้นทาง"
            case .listenError(let err):
                return "เปิดพอร์ตรับสัญญาณล้มเหลว: \(err)"
            case .sourceConnectedAwaitingAuth:
                return "Mac ต้นทางเชื่อมต่อแล้ว · รอตรวจสอบรหัส"
            case .pairingCodeMismatch:
                return "รหัสจับคู่ (Pairing Code) ไม่ตรงกัน"
            case .reconnectingWithNewCode:
                return "กำลังเชื่อมต่อใหม่ด้วยรหัสใหม่…"
            case .blockedUnauthenticated:
                return "บล็อกข้อมูลที่ไม่ได้ยืนยันตัวตน"
            case .blockedInvalidData:
                return "บล็อกข้อมูลที่ไม่ถูกต้อง"
            case .disconnectedWaiting:
                return "การเชื่อมต่อขาดหาย · รอการเชื่อมต่อใหม่"
            case .reallowInputMonitoring:
                return "โปรดอนุญาตสิทธิ์การตรวจสอบการป้อนข้อมูลอีกครั้ง"
            case .custom(let str):
                return str
            }
        case .en:
            switch self {
            case .starting:
                return "Starting…"
            case .off:
                return "Off"
            case .permissionRequired:
                return "Input Monitoring permission required"
            case .searchingTarget:
                return "Searching for Target Mac…"
            case .searchError(let err):
                return "Search error: \(err)"
            case .connectingTarget:
                return "Connecting to Target Mac…"
            case .authenticating:
                return "Authenticating…"
            case .connectionError(let err):
                return "Connection error: \(err)"
            case .connectedSyncing:
                return "Connected · Syncing TH/ENG"
            case .invalidResponse:
                return "Invalid response"
            case .sendError(let err):
                return "Transmission error: \(err)"
            case .disconnectedSearching:
                return "Disconnected · Searching again…"
            case .readyWaitingForSource:
                return "Ready · Waiting for Source Mac"
            case .listenError(let err):
                return "Listening failed: \(err)"
            case .sourceConnectedAwaitingAuth:
                return "Source Mac connected · Awaiting authentication"
            case .pairingCodeMismatch:
                return "Pairing code mismatch"
            case .reconnectingWithNewCode:
                return "Reconnecting with new pairing code…"
            case .blockedUnauthenticated:
                return "Blocked unauthenticated data"
            case .blockedInvalidData:
                return "Blocked invalid data"
            case .disconnectedWaiting:
                return "Disconnected · Waiting…"
            case .reallowInputMonitoring:
                return "Please re-allow Input Monitoring permission"
            case .custom(let str):
                return str
            }
        }
    }
}

public enum LaunchAtLoginFeedbackKey: Equatable {
    case requiresApproval
    case unavailable
    case error(String)

    public func localized(for language: AppLanguage) -> String {
        switch language {
        case .th:
            switch self {
            case .requiresApproval:
                return "โปรดอนุญาตให้ Universal Control Helper ทำงานอัตโนมัติในการตั้งค่าระบบ macOS"
            case .unavailable:
                return "กรุณาย้ายแอปไปที่โฟลเดอร์ Applications ก่อนลองใหม่อีกครั้ง"
            case .error(let msg):
                return "ไม่สามารถเปลี่ยนการตั้งค่าเปิดอัตโนมัติได้: \(msg)"
            }
        case .en:
            switch self {
            case .requiresApproval:
                return "Please allow Universal Control Helper to launch at login in macOS System Settings."
            case .unavailable:
                return "Please move the app to the Applications folder and try again."
            case .error(let msg):
                return "Failed to change launch at login setting: \(msg)"
            }
        }
    }
}

public enum L10n {
    public enum Key {
        case appName
        case appSubtitle
        case appIconAccessibility
        case settingsWindowTitle
        case sectionGeneral
        case enableHelper
        case launchAtLogin
        case openLoginSettings
        case labelAppLanguage
        case sectionConnection
        case rolePickerLabel
        case roleSource
        case roleTarget
        case connectionStatusLabel
        case pairingCodeLabel
        case regenerateCode
        case regenerateCodeAccessibility
        case applyCode
        case applyCodeAccessibility
        case pairingCodePlaceholder
        case pairingCodeFeedbackApplied
        case pairingCodeFeedbackInvalid
        case pairingCodeFeedbackRegenerated
        case pairingCodeHintSource
        case pairingCodeHintTarget
        case roleExplanationSource
        case roleExplanationTarget
        case sectionInputPermissions
        case inputMonitoringLabel
        case permissionDescReady
        case permissionDescGrantedNotStarted
        case permissionDescDenied
        case permissionDescNotDetermined
        case permissionHint
        case openSettings
        case openInputSettingsAccessibility
        case resetPermissions
        case revealApp
        case recheckPermission
        case sectionSoftwareUpdate
        case currentVersion
        case checkForUpdates
        case checkForUpdatesAccessibility
        case devBuild
        case menuSettings
        case menuLanguage
        case menuCloseWindow
        case menuQuit
        case preventTargetCapsLockTitle
        case preventTargetCapsLockSubtitle
        case alertResetTitle
        case alertResetMessage
        case btnReset
        case btnCancel
        case btnOk
        case alertResetFailureTitle
        case alertResetFailureMessage
        case alertInstructionsTitle
        case alertInstructionsMessage
    }

    public static func string(_ key: Key, language: AppLanguage) -> String {
        switch language {
        case .th:
            switch key {
            case .appName:
                return "Universal Control Helper"
            case .appSubtitle:
                return "สลับและซิงค์ภาษาแป้นพิมพ์ ไทย / อังกฤษ (TH / ENG) ระหว่าง Mac สองเครื่องโดยอัตโนมัติ"
            case .appIconAccessibility:
                return "ไอคอนแอป Universal Control Helper"
            case .settingsWindowTitle:
                return "การตั้งค่า Universal Control Helper"
            case .sectionGeneral:
                return "ทั่วไป"
            case .enableHelper:
                return "เปิดใช้งาน Universal Control Helper"
            case .launchAtLogin:
                return "เปิดทำงานอัตโนมัติเมื่อเข้าสู่ระบบ Mac"
            case .openLoginSettings:
                return "เปิดการตั้งค่ารายการเข้าสู่ระบบ"
            case .labelAppLanguage:
                return "ภาษาของแอป"
            case .sectionConnection:
                return "การเชื่อมต่อ"
            case .rolePickerLabel:
                return "บทบาทของ Mac เครื่องนี้"
            case .roleSource:
                return "Mac แป้นพิมพ์หลัก (Source)"
            case .roleTarget:
                return "Mac ปลายทาง (Target)"
            case .connectionStatusLabel:
                return "สถานะการเชื่อมต่อ"
            case .pairingCodeLabel:
                return "รหัสจับคู่ (Pairing Code)"
            case .regenerateCode:
                return "สร้างรหัสใหม่"
            case .regenerateCodeAccessibility:
                return "สร้างรหัสจับคู่ใหม่"
            case .applyCode:
                return "นำไปใช้"
            case .applyCodeAccessibility:
                return "นำรหัสจับคู่ไปใช้"
            case .pairingCodePlaceholder:
                return "ตัวเลข 6 หลัก"
            case .pairingCodeFeedbackApplied:
                return "นำรหัสไปใช้แล้ว กำลังเชื่อมต่อใหม่…"
            case .pairingCodeFeedbackInvalid:
                return "กรุณากรอกตัวเลข 6 หลักให้ถูกต้อง"
            case .pairingCodeFeedbackRegenerated:
                return "สร้างรหัสใหม่แล้ว กรุณากรอกรหัสนี้ที่ Mac ปลายทาง (Target)"
            case .pairingCodeHintSource:
                return "นำรหัสนี้ไปกรอกบน Mac ปลายทาง (Target)"
            case .pairingCodeHintTarget:
                return "กรอกรหัสตัวเลข 6 หลักที่แสดงบน Mac ต้นทาง (Source)"
            case .roleExplanationSource:
                return "ส่งคำสั่งปุ่ม Caps Lock / สลับภาษา และซิงค์แป้นพิมพ์ ไทย (TH) / อังกฤษ (ENG) ไปยัง Mac ปลายทาง"
            case .roleExplanationTarget:
                return "รับคำสั่งและเปลี่ยนภาษาแป้นพิมพ์ ไทย (TH) / อังกฤษ (ENG) ตาม Mac ต้นทางทันที"
            case .sectionInputPermissions:
                return "สิทธิ์การป้อนข้อมูล (เฉพาะ Mac ต้นทาง)"
            case .inputMonitoringLabel:
                return "การตรวจสอบการป้อนข้อมูล (Input Monitoring)"
            case .permissionDescReady:
                return "พร้อมใช้งาน · กำลังตรวจจับปุ่ม Caps Lock / สลับภาษา"
            case .permissionDescGrantedNotStarted:
                return "ได้รับสิทธิ์แล้วแต่ระบบตรวจจับยังไม่เริ่มทำงาน โปรดเปิดแอปใหม่อีกครั้ง"
            case .permissionDescDenied:
                return "ยังไม่ได้รับอนุญาต · โปรดเปิดสิทธิ์ในการตั้งค่าระบบ หรือลงทะเบียนสิทธิ์ใหม่"
            case .permissionDescNotDetermined:
                return "ยังไม่ได้รับอนุญาต · โปรดอนุญาตสิทธิ์การตรวจสอบการป้อนข้อมูลในตั้งค่าระบบ"
            case .permissionHint:
                return "หากเปิดสวิตช์ในตั้งค่าระบบแล้วยังขึ้นว่าไม่ได้รับสิทธิ์ ให้กด 'ลงทะเบียนสิทธิ์ใหม่' หากแอปไม่ปรากฏในรายการ ให้กด + เพื่อเพิ่มแอปด้วยตนเอง"
            case .openSettings:
                return "เปิดการตั้งค่าระบบ"
            case .openInputSettingsAccessibility:
                return "เปิดการตั้งค่าการตรวจสอบการป้อนข้อมูล"
            case .resetPermissions:
                return "ลงทะเบียนสิทธิ์ใหม่…"
            case .revealApp:
                return "ดูตำแหน่งแอปใน Finder"
            case .recheckPermission:
                return "ตรวจสอบสิทธิ์อีกครั้ง"
            case .sectionSoftwareUpdate:
                return "การอัปเดตซอฟต์แวร์"
            case .currentVersion:
                return "เวอร์ชันปัจจุบัน"
            case .checkForUpdates:
                return "ตรวจสอบการอัปเดต…"
            case .checkForUpdatesAccessibility:
                return "ตรวจสอบการอัปเดตเวอร์ชันใหม่"
            case .devBuild:
                return "เวอร์ชันสำหรับการพัฒนา"
            case .menuSettings:
                return "การตั้งค่า…"
            case .menuLanguage:
                return "ภาษา (Language)"
            case .menuCloseWindow:
                return "ปิดหน้าต่าง"
            case .menuQuit:
                return "ออกจาก Universal Control Helper"
            case .preventTargetCapsLockTitle:
                return "ป้องกัน Caps Lock ค้างบน Mac ปลายทาง (Target)"
            case .preventTargetCapsLockSubtitle:
                return "ปิดสถานะ Caps Lock อัตโนมัติเมื่อมีการสลับภาษา เพื่อไม่ให้ติดตัวพิมพ์ใหญ่ตลอดเวลา"
            case .alertResetTitle:
                return "ต้องการลงทะเบียนสิทธิ์การตรวจสอบการป้อนข้อมูลใหม่หรือไม่?"
            case .alertResetMessage:
                return "ระบบจะล้างเฉพาะรายการสิทธิ์เดิมของ Universal Control Helper เพื่อแก้ไขปัญหา macOS จำสิทธิ์ผิดพลาด โดยไม่กระทบแอปอื่น หากรีเซ็ตแล้วแอปไม่ขึ้นในรายการ ให้กดเครื่องหมาย + แล้วเลือก /Applications/Universal Control Helper.app"
            case .btnReset:
                return "ลงทะเบียนใหม่"
            case .btnCancel:
                return "ยกเลิก"
            case .btnOk:
                return "ตกลง"
            case .alertResetFailureTitle:
                return "ไม่สามารถล้างรายการสิทธิ์ได้"
            case .alertResetFailureMessage:
                return "โปรดเปิด Terminal แล้วรันคำสั่งต่อไปนี้:\n\ntccutil reset ListenEvent io.yoonsungji.UniInputFix"
            case .alertInstructionsTitle:
                return "โปรดอนุญาตสิทธิ์การตรวจสอบการป้อนข้อมูล"
            case .alertInstructionsMessage:
                return "หากมี Universal Control Helper ในรายการ ให้เปิดสวิตช์ หากไม่มี ให้กด + เพื่อเลือกแอป และเมื่อ macOS แจ้งเตือน ให้ปิดและเปิดแอปใหม่อีกครั้ง คุณสามารถกดปุ่ม 'ดูตำแหน่งแอปใน Finder' ในหน้าต่างตั้งค่าได้"
            }
        case .en:
            switch key {
            case .appName:
                return "Universal Control Helper"
            case .appSubtitle:
                return "Automatically sync Thai / English (TH / ENG) input sources between two Macs."
            case .appIconAccessibility:
                return "Universal Control Helper App Icon"
            case .settingsWindowTitle:
                return "Universal Control Helper Settings"
            case .sectionGeneral:
                return "General"
            case .enableHelper:
                return "Enable Universal Control Helper"
            case .launchAtLogin:
                return "Launch automatically at login"
            case .openLoginSettings:
                return "Open Login Items Settings"
            case .labelAppLanguage:
                return "App Language"
            case .sectionConnection:
                return "Connection"
            case .rolePickerLabel:
                return "Role of this Mac"
            case .roleSource:
                return "Keyboard Mac (Source)"
            case .roleTarget:
                return "Target Mac (Target)"
            case .connectionStatusLabel:
                return "Connection Status"
            case .pairingCodeLabel:
                return "Pairing Code"
            case .regenerateCode:
                return "Regenerate"
            case .regenerateCodeAccessibility:
                return "Regenerate pairing code"
            case .applyCode:
                return "Apply"
            case .applyCodeAccessibility:
                return "Apply pairing code"
            case .pairingCodePlaceholder:
                return "6 digits"
            case .pairingCodeFeedbackApplied:
                return "Applied. Reconnecting with new code…"
            case .pairingCodeFeedbackInvalid:
                return "Please enter exactly 6 digits."
            case .pairingCodeFeedbackRegenerated:
                return "New code generated. Enter this code on the Target Mac."
            case .pairingCodeHintSource:
                return "Enter this code on your Target Mac."
            case .pairingCodeHintTarget:
                return "Enter the 6-digit code shown on your Source Mac."
            case .roleExplanationSource:
                return "Monitors Caps Lock / language switch and automatically syncs Thai (TH) / English (ENG) to the Target Mac."
            case .roleExplanationTarget:
                return "Applies Thai (TH) / English (ENG) input source changes sent from the Source Mac."
            case .sectionInputPermissions:
                return "Input Permissions (Source only)"
            case .inputMonitoringLabel:
                return "Input Monitoring"
            case .permissionDescReady:
                return "Ready · Monitoring physical Caps Lock / language switch"
            case .permissionDescGrantedNotStarted:
                return "Permission granted but monitoring failed to start. Please restart the app."
            case .permissionDescDenied:
                return "Denied for this build · Allow in System Settings or reset permission entry."
            case .permissionDescNotDetermined:
                return "Not determined yet · Allow Input Monitoring in System Settings."
            case .permissionHint:
                return "If the switch is ON in Settings but still shows unpermitted, reset permissions. If the app doesn't appear in the list, click + to add it manually."
            case .openSettings:
                return "Open Settings"
            case .openInputSettingsAccessibility:
                return "Open Input Monitoring settings"
            case .resetPermissions:
                return "Reset Permissions…"
            case .revealApp:
                return "Show in Finder"
            case .recheckPermission:
                return "Recheck Permission"
            case .sectionSoftwareUpdate:
                return "Software Update"
            case .currentVersion:
                return "Current Version"
            case .checkForUpdates:
                return "Check for Updates…"
            case .checkForUpdatesAccessibility:
                return "Check for updates"
            case .devBuild:
                return "Development Build"
            case .menuSettings:
                return "Settings…"
            case .menuLanguage:
                return "Language (ภาษา)"
            case .menuCloseWindow:
                return "Close Window"
            case .menuQuit:
                return "Quit Universal Control Helper"
            case .preventTargetCapsLockTitle:
                return "Prevent stuck Caps Lock on Target Mac"
            case .preventTargetCapsLockSubtitle:
                return "Automatically disengages Caps Lock when switching languages to prevent uppercase lock."
            case .alertResetTitle:
                return "Reset Input Monitoring permission entry?"
            case .alertResetMessage:
                return "This removes only the Universal Control Helper permission entry to fix macOS caching issues, without affecting other apps. If the app does not appear after reset, click + and select /Applications/Universal Control Helper.app."
            case .btnReset:
                return "Reset"
            case .btnCancel:
                return "Cancel"
            case .btnOk:
                return "OK"
            case .alertResetFailureTitle:
                return "Failed to reset permission entry"
            case .alertResetFailureMessage:
                return "Please run the following command in Terminal:\n\ntccutil reset ListenEvent io.yoonsungji.UniInputFix"
            case .alertInstructionsTitle:
                return "Please grant Input Monitoring permission"
            case .alertInstructionsMessage:
                return "If Universal Control Helper is listed, turn on the switch. If not, click + to add it. When prompted by macOS, quit and reopen the app. You can click 'Show in Finder' in Settings to locate it."
            }
        }
    }
}
