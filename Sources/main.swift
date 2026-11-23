import Cocoa
import Carbon

// MARK: - App Settings

final class AppSettings {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let pcHangulKeyEnabled = "pcHangulKeyEnabled"
        static let pcHanjaKeyEnabled = "pcHanjaKeyEnabled"
        static let winCtrlSwapEnabled = "winCtrlSwapEnabled"
        static let winShortcutsEnabled = "winShortcutsEnabled"
        static let capsLockUppercaseOnlyEnabled = "capsLockUppercaseOnlyEnabled"
        static let shiftSpaceEnabled = "shiftSpaceEnabled"
        static let winHomeEndEnabled = "winHomeEndEnabled"
        static let hudEnabled = "hudEnabled"
        static let hudCentered = "hudCentered"
        static let customTriggerKeyCode = "customTriggerKeyCode"
        static let customTriggerModifiers = "customTriggerModifiers"
        static let customTriggerIsModifier = "customTriggerIsModifier"
        static let customTriggerLabel = "customTriggerLabel"
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    private init() {
        defaults.register(defaults: [
            Keys.pcHangulKeyEnabled: true,
            Keys.pcHanjaKeyEnabled: true,
            Keys.winCtrlSwapEnabled: true,
            Keys.winShortcutsEnabled: true,
            Keys.capsLockUppercaseOnlyEnabled: true,
            Keys.shiftSpaceEnabled: false,
            Keys.winHomeEndEnabled: true,
            Keys.hudEnabled: true,
            Keys.hudCentered: false,
            Keys.customTriggerKeyCode: -1,
            Keys.customTriggerModifiers: 0,
            Keys.customTriggerIsModifier: false,
            Keys.customTriggerLabel: "",
            Keys.hasLaunchedBefore: false
        ])
    }

    var pcHangulKeyEnabled: Bool {
        get { defaults.bool(forKey: Keys.pcHangulKeyEnabled) }
        set { defaults.set(newValue, forKey: Keys.pcHangulKeyEnabled) }
    }

    var pcHanjaKeyEnabled: Bool {
        get { defaults.bool(forKey: Keys.pcHanjaKeyEnabled) }
        set { defaults.set(newValue, forKey: Keys.pcHanjaKeyEnabled) }
    }

    var winCtrlSwapEnabled: Bool {
        get { defaults.bool(forKey: Keys.winCtrlSwapEnabled) }
        set { defaults.set(newValue, forKey: Keys.winCtrlSwapEnabled) }
    }

    var winShortcutsEnabled: Bool {
        get { defaults.bool(forKey: Keys.winShortcutsEnabled) }
        set { defaults.set(newValue, forKey: Keys.winShortcutsEnabled) }
    }

    var capsLockUppercaseOnlyEnabled: Bool {
        get { defaults.bool(forKey: Keys.capsLockUppercaseOnlyEnabled) }
        set { defaults.set(newValue, forKey: Keys.capsLockUppercaseOnlyEnabled) }
    }

    var shiftSpaceEnabled: Bool {
        get { defaults.bool(forKey: Keys.shiftSpaceEnabled) }
        set { defaults.set(newValue, forKey: Keys.shiftSpaceEnabled) }
    }

    var winHomeEndEnabled: Bool {
        get { defaults.bool(forKey: Keys.winHomeEndEnabled) }
        set { defaults.set(newValue, forKey: Keys.winHomeEndEnabled) }
    }

    var hudEnabled: Bool {
        get { defaults.bool(forKey: Keys.hudEnabled) }
        set { defaults.set(newValue, forKey: Keys.hudEnabled) }
    }

    var hudCentered: Bool {
        get { defaults.bool(forKey: Keys.hudCentered) }
        set { defaults.set(newValue, forKey: Keys.hudCentered) }
    }

    var customTriggerKeyCode: Int {
        get { defaults.integer(forKey: Keys.customTriggerKeyCode) }
        set { defaults.set(newValue, forKey: Keys.customTriggerKeyCode) }
    }

    var customTriggerModifiers: Int {
        get { defaults.integer(forKey: Keys.customTriggerModifiers) }
        set { defaults.set(newValue, forKey: Keys.customTriggerModifiers) }
    }

    var customTriggerIsModifier: Bool {
        get { defaults.bool(forKey: Keys.customTriggerIsModifier) }
        set { defaults.set(newValue, forKey: Keys.customTriggerIsModifier) }
    }

    var customTriggerLabel: String {
        get { defaults.string(forKey: Keys.customTriggerLabel) ?? "" }
        set { defaults.set(newValue, forKey: Keys.customTriggerLabel) }
    }

    var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: Keys.hasLaunchedBefore) }
        set { defaults.set(newValue, forKey: Keys.hasLaunchedBefore) }
    }
}

// MARK: - HID Hardware Key Mapper (hidutil)

final class HIDMapper {
    static let shared = HIDMapper()
    private let queue = DispatchQueue(label: "com.kswitch.hidutil", qos: .userInitiated)

    // USB HID Usage IDs (Keyboard/Keypad Page 0x07)
    private let usageLang1: UInt64 = 0x700000090       // PC 한/영 (Kana / Hangul)
    private let usageLang2: UInt64 = 0x700000091       // PC 한자 (Hanja / Eisu)
    private let usageLeftCtrl: UInt64 = 0x7000000E0    // PC Left Ctrl
    private let usageLeftGUI: UInt64 = 0x7000000E3     // PC Left Win (macOS Left Command)
    private let usageRightAlt: UInt64 = 0x7000000E6    // PC Right Alt (macOS Right Option)
    private let usageRightCtrl: UInt64 = 0x7000000E4   // PC Right Ctrl (한자 겸용)
    private let usageF18: UInt64 = 0x70000006D         // F18 (Virtual Bridge for 한/영)
    private let usageF20: UInt64 = 0x70000006F         // F20 (Virtual Bridge for 한자)

    private(set) var lastStatusMessage: String = "초기화 중..."
    private(set) var isMappingActive: Bool = false

    private init() {}

    func applyCurrentSettings(completion: ((Bool, String) -> Void)? = nil) {
        let settings = AppSettings.shared
        var mappings: [[String: UInt64]] = []

        if settings.pcHangulKeyEnabled {
            mappings.append([
                "HIDKeyboardModifierMappingSrc": usageLang1,
                "HIDKeyboardModifierMappingDst": usageF18
            ])
            mappings.append([
                "HIDKeyboardModifierMappingSrc": usageRightAlt,
                "HIDKeyboardModifierMappingDst": usageF18
            ])
        }

        if settings.pcHanjaKeyEnabled {
            mappings.append([
                "HIDKeyboardModifierMappingSrc": usageLang2,
                "HIDKeyboardModifierMappingDst": usageF20
            ])
            mappings.append([
                "HIDKeyboardModifierMappingSrc": usageRightCtrl,
                "HIDKeyboardModifierMappingDst": usageF20
            ])
        }

        if settings.winCtrlSwapEnabled {
            mappings.append([
                "HIDKeyboardModifierMappingSrc": usageLeftCtrl,
                "HIDKeyboardModifierMappingDst": usageLeftGUI
            ])
            mappings.append([
                "HIDKeyboardModifierMappingSrc": usageLeftGUI,
                "HIDKeyboardModifierMappingDst": usageLeftCtrl
            ])
        }

        let payload: [String: Any] = ["UserKeyMapping": mappings]
        runHidutil(payload: payload, activeCount: mappings.count, completion: completion)
    }

    func resetMappingsSync() {
        let payload: [String: Any] = ["UserKeyMapping": []]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        process.arguments = ["property", "--set", json]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
    }

    private func runHidutil(payload: [String: Any], activeCount: Int, completion: ((Bool, String) -> Void)?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let data = try? JSONSerialization.data(withJSONObject: payload),
                  let json = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.isMappingActive = false
                    self.lastStatusMessage = "매핑 JSON 생성 오류"
                    completion?(false, self.lastStatusMessage)
                }
                return
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
            process.arguments = ["property", "--set", json]
            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            do {
                try process.run()
                process.waitUntilExit()
                let ok = (process.terminationStatus == 0)
                let msg: String
                if ok {
                    msg = activeCount > 0 ? "정상 작동 중 (\(activeCount)개 키 브릿지 활성)" : "매핑 비활성 (원본 키 유지)"
                } else {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    msg = "hidutil 오류 (code \(process.terminationStatus)): \(errStr)"
                }
                DispatchQueue.main.async {
                    self.isMappingActive = ok && activeCount > 0
                    self.lastStatusMessage = msg
                    completion?(ok, msg)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isMappingActive = false
                    self.lastStatusMessage = "실행 실패: \(error.localizedDescription)"
                    completion?(false, self.lastStatusMessage)
                }
            }
        }
    }
}

// MARK: - LaunchAgent Manager (Login Item)

final class LaunchAgentManager {
    static let shared = LaunchAgentManager()
    private let label = "com.kswitch.app"

    private var plistURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        let fm = FileManager.default
        if !enabled {
            if fm.fileExists(atPath: plistURL.path) {
                try? fm.removeItem(at: plistURL)
            }
            return true
        }

        guard let executablePath = Bundle.main.executablePath else { return false }
        let launchAgentsDir = plistURL.deletingLastPathComponent()
        try? fm.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "ProcessType": "Interactive"
        ]

        guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else {
            return false
        }

        do {
            try data.write(to: plistURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Windows Home/End KeyBinding Manager

final class HomeEndFixManager {
    static let shared = HomeEndFixManager()
    private let marker = "/* KSwitch Windows Home/End Fix */"

    private var keyBindingsDir: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/KeyBindings")
    }

    private var dictURL: URL {
        keyBindingsDir.appendingPathComponent("DefaultKeyBinding.dict")
    }

    private var backupURL: URL {
        keyBindingsDir.appendingPathComponent("DefaultKeyBinding.dict.kswitch_backup")
    }

    private let kswitchDictContent = """
    /* KSwitch Windows Home/End Fix */
    {
        "\\UF729"  = "moveToBeginningOfLine:";
        "$\\UF729" = "moveToBeginningOfLineAndModifySelection:";
        "^\\UF729" = "moveToBeginningOfDocument:";
        "^$\\UF729" = "moveToBeginningOfDocumentAndModifySelection:";
        "\\UF72B"  = "moveToEndOfLine:";
        "$\\UF72B" = "moveToEndOfLineAndModifySelection:";
        "^\\UF72B" = "moveToEndOfDocument:";
        "^$\\UF72B" = "moveToEndOfDocumentAndModifySelection:";
    }
    """

    private init() {}

    func syncWithSettings() {
        setEnabled(AppSettings.shared.winHomeEndEnabled)
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        let fm = FileManager.default
        if enabled {
            do {
                try fm.createDirectory(at: keyBindingsDir, withIntermediateDirectories: true)
                if fm.fileExists(atPath: dictURL.path) {
                    let current = (try? String(contentsOf: dictURL, encoding: .utf8)) ?? ""
                    if current.contains(marker) {
                        return true
                    }
                    if !fm.fileExists(atPath: backupURL.path) {
                        try fm.copyItem(at: dictURL, to: backupURL)
                    }
                }
                try kswitchDictContent.write(to: dictURL, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        } else {
            do {
                if fm.fileExists(atPath: backupURL.path) {
                    if fm.fileExists(atPath: dictURL.path) {
                        try fm.removeItem(at: dictURL)
                    }
                    try fm.moveItem(at: backupURL, to: dictURL)
                } else if fm.fileExists(atPath: dictURL.path) {
                    let current = (try? String(contentsOf: dictURL, encoding: .utf8)) ?? ""
                    if current.contains(marker) {
                        try fm.removeItem(at: dictURL)
                    }
                }
                return true
            } catch {
                return false
            }
        }
    }
}

// MARK: - Hanja Key Converter

final class HanjaConverter {
    static let shared = HanjaConverter()
    private init() {}

    func triggerHanjaConversion() {
        DispatchQueue.main.async {
            guard AXIsProcessTrusted() else {
                HUDController.shared.showNotice(
                    glyph: "漢",
                    caption: "권한 필요",
                    accentColor: NSColor.systemOrange
                )
                HotKeyEngine.shared.promptAccessibilityPermission()
                return
            }

            // macOS standard Korean Hanja conversion shortcut: Option + Return
            guard let source = CGEventSource(stateID: .hidSystemState),
                  let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Return), keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Return), keyDown: false) else {
                return
            }
            keyDown.flags = .maskAlternate
            keyUp.flags = .maskAlternate
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }
}

// MARK: - Caps Lock Mode Manager (HIToolbox TISSetRomanSwitchState)

@_silgen_name("TISSetRomanSwitchState")
private func TISSetRomanSwitchState(_ state: Int32)

@_silgen_name("TISIsRomanSwitchEnabled")
private func TISIsRomanSwitchEnabled() -> Bool

final class CapsLockManager {
    static let shared = CapsLockManager()

    private init() {}

    func syncWithSettings() {
        setUppercaseOnly(AppSettings.shared.capsLockUppercaseOnlyEnabled)
    }

    func setUppercaseOnly(_ uppercaseOnly: Bool, completion: ((Bool) -> Void)? = nil) {
        let apply = {
            TISSetRomanSwitchState(uppercaseOnly ? 0 : 1)
            let ok = (TISIsRomanSwitchEnabled() == !uppercaseOnly)
            completion?(ok)
        }

        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.async(execute: apply)
        }
    }
}

// MARK: - Windows Key Shortcuts Manager (Win+E/D/L/Shift+S)

final class WinShortcutsManager {
    static let shared = WinShortcutsManager()

    private typealias CoreDockSendNotificationFn = @convention(c) (CFString, UnsafeMutableRawPointer?) -> Void
    private typealias SACLockScreenImmediateFn = @convention(c) () -> Void

    private lazy var coreDockNotify: CoreDockSendNotificationFn? = {
        guard let handle = dlopen("/System/Library/Frameworks/ApplicationServices.framework/Frameworks/HIServices.framework/HIServices", RTLD_LAZY),
              let sym = dlsym(handle, "CoreDockSendNotification") else {
            return nil
        }
        return unsafeBitCast(sym, to: CoreDockSendNotificationFn.self)
    }()

    private lazy var lockScreenFn: SACLockScreenImmediateFn? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/login", RTLD_LAZY),
              let sym = dlsym(handle, "SACLockScreenImmediate") else {
            return nil
        }
        return unsafeBitCast(sym, to: SACLockScreenImmediateFn.self)
    }()

    private init() {}

    func openFinder() {
        DispatchQueue.main.async {
            let homePath = FileManager.default.homeDirectoryForCurrentUser.path
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: homePath)
            HUDController.shared.showNotice(glyph: "📁", caption: "Finder 열기", accentColor: NSColor.white)
        }
    }

    func toggleShowDesktop() {
        DispatchQueue.main.async { [weak self] in
            self?.coreDockNotify?("com.apple.showdesktop.awake" as CFString, nil)
        }
    }

    func lockScreen() {
        DispatchQueue.main.async { [weak self] in
            self?.lockScreenFn?()
        }
    }

    func captureAreaToClipboard() {
        DispatchQueue.main.async {
            let screenshotURL = URL(fileURLWithPath: "/System/Applications/Utilities/Screenshot.app")
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: screenshotURL, configuration: config, completionHandler: nil)
        }
    }
}

// MARK: - Input Source Manager (Carbon HIToolbox)

final class InputSourceManager {
    static let shared = InputSourceManager()

    struct SourceInfo: Equatable {
        let id: String
        let name: String
        let isKorean: Bool
    }

    var onSourceChanged: ((SourceInfo, Bool) -> Void)?

    private var lastKoreanSourceID: String = "com.apple.inputmethod.Korean.2SetKorean"
    private var lastEnglishSourceID: String = "com.apple.keylayout.ABC"
    private var lastToggleTimestamp: TimeInterval = 0
    private var lastReportedID: String = ""
    private var expectedIsKorean: Bool?
    private var toggleGeneration: UInt64 = 0
    private var retryWorkItems: [DispatchWorkItem] = []

    private init() {
        syncHistoryWithCurrent()
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSystemInputSourceChange),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }

    func currentSourceInfo() -> SourceInfo {
        guard let currentRef = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return SourceInfo(id: "unknown", name: "Unknown", isKorean: false)
        }
        let id = stringProperty(currentRef, kTISPropertyInputSourceID) ?? "unknown"
        let name = stringProperty(currentRef, kTISPropertyLocalizedName) ?? id
        let isKorean = isKoreanSourceID(id)
        return SourceInfo(id: id, name: name, isKorean: isKorean)
    }

    func toggleInputSource() {
        let performToggle = { [weak self] in
            guard let self = self else { return }

            for item in self.retryWorkItems {
                item.cancel()
            }
            self.retryWorkItems.removeAll()

            let now = ProcessInfo.processInfo.systemUptime
            let currentIsKorean: Bool
            if now - self.lastToggleTimestamp < 0.28, let pending = self.expectedIsKorean {
                currentIsKorean = pending
            } else {
                currentIsKorean = self.currentSourceInfo().isKorean
            }

            let targetIsKorean = !currentIsKorean
            let sources = self.selectableKeyboardSources()
            let targetSource = targetIsKorean
                ? self.findBestKoreanSource(in: sources)
                : self.findBestEnglishSource(in: sources)

            guard let target = targetSource else { return }
            let targetID = self.stringProperty(target, kTISPropertyInputSourceID) ?? ""
            let targetName = self.stringProperty(target, kTISPropertyLocalizedName) ?? targetID

            self.expectedIsKorean = targetIsKorean
            self.lastToggleTimestamp = now
            self.toggleGeneration &+= 1
            let gen = self.toggleGeneration

            let status = TISSelectInputSource(target)
            if status == noErr {
                self.lastReportedID = targetID
                let info = SourceInfo(id: targetID, name: targetName, isKorean: targetIsKorean)
                self.recordHistory(info)
                self.onSourceChanged?(info, true)
            }

            // Verify & retry if KoreanIME absorbed the first switch while committing a syllable
            for delay in [0.025, 0.060] {
                let item = DispatchWorkItem { [weak self] in
                    guard let self = self, self.toggleGeneration == gen else { return }
                    let actual = self.currentSourceInfo()
                    if actual.id != targetID && actual.isKorean != targetIsKorean {
                        _ = TISSelectInputSource(target)
                    }
                }
                self.retryWorkItems.append(item)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
            }
        }

        if Thread.isMainThread {
            performToggle()
        } else {
            DispatchQueue.main.async(execute: performToggle)
        }
    }

    @objc private func handleSystemInputSourceChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let info = self.currentSourceInfo()
            self.recordHistory(info)

            // Avoid stale transient notifications or duplicate HUD right after our own toggle
            let elapsed = ProcessInfo.processInfo.systemUptime - self.lastToggleTimestamp
            if elapsed < 0.28 {
                if info.id == self.lastReportedID || info.isKorean == self.expectedIsKorean {
                    self.onSourceChanged?(info, false)
                }
                return
            }

            self.expectedIsKorean = nil
            let changed = (info.id != self.lastReportedID)
            self.lastReportedID = info.id
            self.onSourceChanged?(info, changed)
        }
    }

    private func syncHistoryWithCurrent() {
        let info = currentSourceInfo()
        lastReportedID = info.id
        recordHistory(info)
    }

    private func recordHistory(_ info: SourceInfo) {
        if info.isKorean {
            lastKoreanSourceID = info.id
        } else if isEnglishOrASCIISource(id: info.id) {
            lastEnglishSourceID = info.id
        }
    }

    private func isKoreanSourceID(_ id: String) -> Bool {
        return id.hasPrefix("com.apple.inputmethod.Korean") ||
               id.localizedCaseInsensitiveContains("gureum") ||
               id.localizedCaseInsensitiveContains("Hangul")
    }

    private func isEnglishOrASCIISource(id: String) -> Bool {
        return id.hasPrefix("com.apple.keylayout.")
    }

    private func selectableKeyboardSources() -> [TISInputSource] {
        let filter = [kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        return list.filter { source in
            boolProperty(source, kTISPropertyInputSourceIsEnabled) &&
            boolProperty(source, kTISPropertyInputSourceIsSelectCapable)
        }
    }

    private func findBestKoreanSource(in sources: [TISInputSource]) -> TISInputSource? {
        if let exactLast = sources.first(where: { stringProperty($0, kTISPropertyInputSourceID) == lastKoreanSourceID }) {
            return exactLast
        }
        if let twoSet = sources.first(where: { stringProperty($0, kTISPropertyInputSourceID) == "com.apple.inputmethod.Korean.2SetKorean" }) {
            return twoSet
        }
        return sources.first(where: {
            let id = stringProperty($0, kTISPropertyInputSourceID) ?? ""
            return isKoreanSourceID(id)
        })
    }

    private func findBestEnglishSource(in sources: [TISInputSource]) -> TISInputSource? {
        if let exactLast = sources.first(where: { stringProperty($0, kTISPropertyInputSourceID) == lastEnglishSourceID }) {
            return exactLast
        }
        if let abc = sources.first(where: { stringProperty($0, kTISPropertyInputSourceID) == "com.apple.keylayout.ABC" }) {
            return abc
        }
        if let us = sources.first(where: { stringProperty($0, kTISPropertyInputSourceID) == "com.apple.keylayout.US" }) {
            return us
        }
        if let ascii = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue() {
            return ascii
        }
        return sources.first(where: {
            let id = stringProperty($0, kTISPropertyInputSourceID) ?? ""
            return !isKoreanSourceID(id)
        })
    }

    private func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    private func boolProperty(_ source: TISInputSource, _ key: CFString) -> Bool {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return false }
        let val = Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue()
        return CFBooleanGetValue(val)
    }
}

// MARK: - Floating HUD Overlay

final class HUDController {
    static let shared = HUDController()

    private var panel: NSPanel?
    private var effectView: NSVisualEffectView?
    private var glyphLabel: NSTextField?
    private var captionLabel: NSTextField?
    private var hideWorkItem: DispatchWorkItem?

    private let hudWidth: CGFloat = 108
    private let hudHeight: CGFloat = 108

    private init() {}

    func show(isKorean: Bool) {
        if isKorean {
            showNotice(
                glyph: "한",
                caption: "한국어",
                accentColor: NSColor(calibratedRed: 0.35, green: 0.78, blue: 1.0, alpha: 1.0)
            )
        } else {
            showNotice(
                glyph: "A",
                caption: "English",
                accentColor: NSColor.white
            )
        }
    }

    func showNotice(glyph: String, caption: String, accentColor: NSColor) {
        guard AppSettings.shared.hudEnabled else { return }

        if panel == nil {
            createPanel()
        }
        guard let panel = panel, let glyphLabel = glyphLabel, let captionLabel = captionLabel else { return }

        hideWorkItem?.cancel()

        glyphLabel.stringValue = glyph
        glyphLabel.font = NSFont.systemFont(ofSize: glyph.count > 1 ? 26 : 44, weight: .bold)
        glyphLabel.textColor = accentColor
        captionLabel.stringValue = caption

        positionPanel(panel)

        panel.alphaValue = 0.0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08
            panel.animator().alphaValue = 1.0
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, let panel = self.panel else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.22
                panel.animator().alphaValue = 0.0
            }, completionHandler: {
                if panel.alphaValue == 0.0 {
                    panel.orderOut(nil)
                }
            })
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55, execute: workItem)
    }

    private func createPanel() {
        let rect = NSRect(x: 0, y: 0, width: hudWidth, height: hudHeight)
        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        let blur = NSVisualEffectView(frame: rect)
        blur.material = .hudWindow
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.appearance = NSAppearance(named: .darkAqua)
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 22
        blur.layer?.masksToBounds = true
        blur.layer?.borderWidth = 1
        blur.layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor

        let glyph = NSTextField(labelWithString: "한")
        glyph.font = NSFont.systemFont(ofSize: 44, weight: .bold)
        glyph.alignment = .center
        glyph.translatesAutoresizingMaskIntoConstraints = false

        let caption = NSTextField(labelWithString: "한국어")
        caption.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        caption.textColor = NSColor.white.withAlphaComponent(0.82)
        caption.alignment = .center
        caption.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [glyph, caption])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        blur.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: blur.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: blur.centerYAnchor)
        ])

        panel.contentView = blur

        self.panel = panel
        self.effectView = blur
        self.glyphLabel = glyph
        self.captionLabel = caption
    }

    private func positionPanel(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main
        guard let targetScreen = screen else { return }

        let visibleFrame = targetScreen.visibleFrame
        let x = visibleFrame.midX - hudWidth / 2
        let y: CGFloat
        if AppSettings.shared.hudCentered {
            y = visibleFrame.midY - hudHeight / 2
        } else {
            y = visibleFrame.minY + max(80, visibleFrame.height * 0.14)
        }
        panel.setFrameOrigin(NSPoint(x: round(x), y: round(y)))
    }
}

// MARK: - Key Detection & HotKey Engine

private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for byte in string.utf8.prefix(4) {
        result = (result << 8) + OSType(byte)
    }
    return result
}

final class HotKeyEngine {
    static let shared = HotKeyEngine()

    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var nextExtraHotKeyID: UInt32 = 100
    private let signature: OSType = fourCharCode("KSWT")
    private var isPausedForRecording = false

    // Optional CGEventTap (only active if user grants Accessibility AND uses a standalone modifier key)
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var activeModifierKeyCode: Int64?
    private var modifierInterrupted = false

    private enum HotKeyID: UInt32 {
        case f18Bridge = 1
        case shiftSpace = 3
        case jisKana = 4
        case customKey = 5
        case f20HanjaBridge = 6
        case jisEisu = 7
        case winE = 8
        case winD = 9
        case winL = 10
        case winShiftS = 11
    }

    private init() {
        installCarbonHandler()
    }

    func reload() {
        unregisterAllHotKeys()
        stopEventTap()

        guard !isPausedForRecording else { return }

        let settings = AppSettings.shared

        if settings.pcHangulKeyEnabled {
            registerHangulHotKeys(baseID: .f18Bridge, keyCode: UInt32(kVK_F18))
            registerHangulHotKeys(baseID: .jisKana, keyCode: UInt32(kVK_JIS_Kana))
        }

        if settings.pcHanjaKeyEnabled {
            registerHotKey(id: .f20HanjaBridge, keyCode: UInt32(kVK_F20), modifiers: 0)
            registerHotKey(id: .jisEisu, keyCode: UInt32(kVK_JIS_Eisu), modifiers: 0)
        }

        if settings.shiftSpaceEnabled {
            registerHotKey(id: .shiftSpace, keyCode: UInt32(kVK_Space), modifiers: UInt32(shiftKey))
        }

        if settings.winShortcutsEnabled {
            registerHotKey(id: .winE, keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(controlKey))
            registerHotKey(id: .winD, keyCode: UInt32(kVK_ANSI_D), modifiers: UInt32(controlKey))
            registerHotKey(id: .winL, keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(controlKey))
            registerHotKey(id: .winShiftS, keyCode: UInt32(kVK_ANSI_S), modifiers: UInt32(controlKey | shiftKey))
        }

        if settings.customTriggerKeyCode >= 0 {
            if settings.customTriggerIsModifier {
                startEventTapIfTrusted()
            } else {
                let carbonMods = carbonModifiers(fromCocoaFlags: NSEvent.ModifierFlags(rawValue: UInt(settings.customTriggerModifiers)))
                registerHotKey(id: .customKey, keyCode: UInt32(settings.customTriggerKeyCode), modifiers: carbonMods)
            }
        }
    }

    func setPausedForRecording(_ paused: Bool) {
        isPausedForRecording = paused
        if paused {
            unregisterAllHotKeys()
            stopEventTap()
        } else {
            reload()
        }
    }

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func promptAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func installCarbonHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let callback: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let event = event, let userData = userData else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            if status == noErr {
                let engine = Unmanaged<HotKeyEngine>.fromOpaque(userData).takeUnretainedValue()
                if hotKeyID.signature == engine.signature {
                    switch hotKeyID.id {
                    case HotKeyID.f20HanjaBridge.rawValue, HotKeyID.jisEisu.rawValue:
                        HanjaConverter.shared.triggerHanjaConversion()
                    case HotKeyID.winE.rawValue:
                        WinShortcutsManager.shared.openFinder()
                    case HotKeyID.winD.rawValue:
                        WinShortcutsManager.shared.toggleShowDesktop()
                    case HotKeyID.winL.rawValue:
                        WinShortcutsManager.shared.lockScreen()
                    case HotKeyID.winShiftS.rawValue:
                        WinShortcutsManager.shared.captureAreaToClipboard()
                    default:
                        InputSourceManager.shared.toggleInputSource()
                    }
                    return noErr
                }
            }
            return OSStatus(eventNotHandledErr)
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
    }

    private func registerHangulHotKeys(baseID: HotKeyID, keyCode: UInt32) {
        registerHotKey(rawID: baseID.rawValue, keyCode: keyCode, modifiers: 0)
        // Catch fast-typing modifier overlaps (e.g., Shift still held from double consonant or '?')
        let overlapModifiers: [UInt32] = [
            UInt32(shiftKey),
            UInt32(optionKey),
            UInt32(cmdKey),
            UInt32(shiftKey | optionKey),
            UInt32(shiftKey | cmdKey)
        ]
        for mods in overlapModifiers {
            let id = nextExtraHotKeyID
            nextExtraHotKeyID &+= 1
            registerHotKey(rawID: id, keyCode: keyCode, modifiers: mods)
        }
    }

    private func registerHotKey(id: HotKeyID, keyCode: UInt32, modifiers: UInt32) {
        registerHotKey(rawID: id.rawValue, keyCode: keyCode, modifiers: modifiers)
    }

    private func registerHotKey(rawID: UInt32, keyCode: UInt32, modifiers: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: rawID)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs.append(ref)
        }
    }

    private func unregisterAllHotKeys() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        nextExtraHotKeyID = 100
    }

    private func carbonModifiers(fromCocoaFlags flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    private func startEventTapIfTrusted() {
        guard AXIsProcessTrusted() else { return }

        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let callback: CGEventTapCallBack = { _, type, event, userData -> Unmanaged<CGEvent>? in
            guard let userData = userData else { return Unmanaged.passUnretained(event) }
            let engine = Unmanaged<HotKeyEngine>.fromOpaque(userData).takeUnretainedValue()

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = engine.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            let targetCode = Int64(AppSettings.shared.customTriggerKeyCode)
            guard targetCode >= 0, AppSettings.shared.customTriggerIsModifier else {
                return Unmanaged.passUnretained(event)
            }

            if type == .keyDown {
                if engine.activeModifierKeyCode != nil {
                    engine.modifierInterrupted = true
                }
                return Unmanaged.passUnretained(event)
            }

            if type == .flagsChanged {
                let code = event.getIntegerValueField(.keyboardEventKeycode)
                if code == targetCode {
                    let isPressed = engine.isModifierCurrentlyPressed(keyCode: code, flags: event.flags)
                    if isPressed {
                        engine.activeModifierKeyCode = code
                        engine.modifierInterrupted = false
                    } else if engine.activeModifierKeyCode == code {
                        let shouldFire = !engine.modifierInterrupted
                        engine.activeModifierKeyCode = nil
                        engine.modifierInterrupted = false
                        if shouldFire {
                            InputSourceManager.shared.toggleInputSource()
                        }
                    }
                } else if engine.activeModifierKeyCode != nil {
                    engine.modifierInterrupted = true
                }
            }

            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: selfPtr
        ) else { return }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = source
    }

    private func stopEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        activeModifierKeyCode = nil
        modifierInterrupted = false
    }

    private func isModifierCurrentlyPressed(keyCode: Int64, flags: CGEventFlags) -> Bool {
        switch Int(keyCode) {
        case kVK_RightOption, kVK_Option:
            return flags.contains(.maskAlternate)
        case kVK_RightCommand, kVK_Command:
            return flags.contains(.maskCommand)
        case kVK_RightControl, kVK_Control:
            return flags.contains(.maskControl)
        case kVK_RightShift, kVK_Shift:
            return flags.contains(.maskShift)
        case kVK_CapsLock:
            return true
        default:
            return false
        }
    }
}

// MARK: - Key Naming Helper

enum KeyCodeHelper {
    static func describe(keyCode: Int, modifiers: NSEvent.ModifierFlags, isModifier: Bool) -> String {
        var parts: [String] = []
        if !isModifier {
            if modifiers.contains(.control) { parts.append("Ctrl") }
            if modifiers.contains(.option) { parts.append("Option") }
            if modifiers.contains(.shift) { parts.append("Shift") }
            if modifiers.contains(.command) { parts.append("Cmd") }
        }
        parts.append(nameForKeyCode(keyCode))
        return parts.joined(separator: " + ")
    }

    static func isModifierKeyCode(_ keyCode: Int) -> Bool {
        switch keyCode {
        case kVK_Command, kVK_RightCommand,
             kVK_Option, kVK_RightOption,
             kVK_Control, kVK_RightControl,
             kVK_Shift, kVK_RightShift,
             kVK_CapsLock, kVK_Function:
            return true
        default:
            return false
        }
    }

    static func nameForKeyCode(_ keyCode: Int) -> String {
        switch keyCode {
        case kVK_F18: return "F18 (일반 키보드 한/영 브릿지)"
        case kVK_F19: return "F19 (Caps Lock 브릿지)"
        case kVK_F20: return "F20 (일반 키보드 한자 브릿지)"
        case kVK_F13: return "F13"
        case kVK_F14: return "F14"
        case kVK_F15: return "F15"
        case kVK_F16: return "F16"
        case kVK_F17: return "F17"
        case kVK_JIS_Kana: return "JIS Kana / 한영"
        case kVK_JIS_Eisu: return "JIS Eisu / 영수"
        case kVK_Space: return "Space"
        case kVK_RightOption: return "오른쪽 Option (Alt)"
        case kVK_Option: return "왼쪽 Option (Alt)"
        case kVK_RightCommand: return "오른쪽 Command (Win)"
        case kVK_Command: return "왼쪽 Command (Win)"
        case kVK_RightControl: return "오른쪽 Control (한자)"
        case kVK_Control: return "왼쪽 Control"
        case kVK_RightShift: return "오른쪽 Shift"
        case kVK_Shift: return "왼쪽 Shift"
        case kVK_CapsLock: return "Caps Lock"
        case 110: return "Application / 메뉴 키"
        default: return "KeyCode \(keyCode)"
        }
    }
}

// MARK: - Dashboard Window Controller

final class DashboardWindowController: NSWindowController, NSWindowDelegate {
    static let shared = DashboardWindowController()

    private var statusBadgeLabel: NSTextField!
    private var statusBadgeBox: NSBox!
    private var pcHangulSwitch: NSSwitch!
    private var pcHanjaSwitch: NSSwitch!
    private var winCtrlSwapSwitch: NSSwitch!
    private var winShortcutsSwitch: NSSwitch!
    private var capsLockSwitch: NSSwitch!
    private var shiftSpaceSwitch: NSSwitch!
    private var winHomeEndSwitch: NSSwitch!
    private var hudSwitch: NSSwitch!
    private var hudCenterCheck: NSButton!
    private var launchAtLoginSwitch: NSSwitch!

    private var hidStatusLabel: NSTextField!
    private var customKeyLabel: NSTextField!
    private var recordKeyButton: NSButton!
    private var clearCustomKeyButton: NSButton!
    private var accessibilityStatusLabel: NSTextField!
    private var accessibilityButton: NSButton!

    private var localKeyMonitor: Any?
    private var isRecordingKey = false

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 865),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "KSwitch (맥한영) 설정"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        window.delegate = self
        setupUI()
        refreshUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showDashboard() {
        refreshUI()
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        stopRecordingKey()
    }

    func refreshUI() {
        guard isWindowLoaded || window != nil else { return }
        let settings = AppSettings.shared

        pcHangulSwitch.state = settings.pcHangulKeyEnabled ? .on : .off
        pcHanjaSwitch.state = settings.pcHanjaKeyEnabled ? .on : .off
        winCtrlSwapSwitch.state = settings.winCtrlSwapEnabled ? .on : .off
        winShortcutsSwitch.state = settings.winShortcutsEnabled ? .on : .off
        capsLockSwitch.state = settings.capsLockUppercaseOnlyEnabled ? .on : .off
        shiftSpaceSwitch.state = settings.shiftSpaceEnabled ? .on : .off
        winHomeEndSwitch.state = settings.winHomeEndEnabled ? .on : .off
        hudSwitch.state = settings.hudEnabled ? .on : .off
        hudCenterCheck.state = settings.hudCentered ? .on : .off
        hudCenterCheck.isEnabled = settings.hudEnabled
        launchAtLoginSwitch.state = LaunchAgentManager.shared.isEnabled ? .on : .off

        let source = InputSourceManager.shared.currentSourceInfo()
        if source.isKorean {
            statusBadgeLabel.stringValue = "한  한국어 (\(source.name))"
            statusBadgeLabel.textColor = NSColor.systemBlue
        } else {
            statusBadgeLabel.stringValue = "A  English (\(source.name))"
            statusBadgeLabel.textColor = NSColor.labelColor
        }

        hidStatusLabel.stringValue = "HID 매핑: \(HIDMapper.shared.lastStatusMessage)"

        if settings.customTriggerKeyCode >= 0 {
            let desc = settings.customTriggerLabel.isEmpty
                ? KeyCodeHelper.describe(
                    keyCode: settings.customTriggerKeyCode,
                    modifiers: NSEvent.ModifierFlags(rawValue: UInt(settings.customTriggerModifiers)),
                    isModifier: settings.customTriggerIsModifier
                )
                : settings.customTriggerLabel
            customKeyLabel.stringValue = "지정된 추가 키: \(desc)"
            clearCustomKeyButton.isEnabled = true
        } else {
            customKeyLabel.stringValue = "지정된 추가 키: 없음 (기본 한/영 키만 사용)"
            clearCustomKeyButton.isEnabled = false
        }

        let trusted = HotKeyEngine.shared.isAccessibilityTrusted
        if trusted {
            accessibilityStatusLabel.stringValue = "손쉬운 사용 권한: 허용됨 (한자 키 & 단독 조합키 활성)"
            accessibilityStatusLabel.textColor = NSColor.systemGreen
            accessibilityButton.isHidden = true
        } else {
            accessibilityStatusLabel.stringValue = "손쉬운 사용 권한: 미허용 (한/영 키는 즉시 작동 • 한자 키 사용 시 필요)"
            accessibilityStatusLabel.textColor = NSColor.secondaryLabelColor
            accessibilityButton.isHidden = false
        }
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let rootStack = NSStackView()
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = 14
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])

        // 1. Header
        let headerRow = NSStackView()
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.distribution = .fill
        headerRow.spacing = 10

        let iconView = NSImageView()
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 42),
            iconView.heightAnchor.constraint(equalToConstant: 42)
        ])

        let titleStack = NSStackView()
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 2

        let titleLabel = NSTextField(labelWithString: "KSwitch 맥한영 v1.2.1")
        titleLabel.font = NSFont.systemFont(ofSize: 19, weight: .bold)

        let subtitleLabel = NSTextField(labelWithString: "일반 PC 키보드 한/영 · 한자 · Ctrl · Win · Home/End")
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = NSColor.secondaryLabelColor

        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)

        let testToggleButton = NSButton(title: "지금 한/영 전환", target: self, action: #selector(handleManualToggle))
        testToggleButton.bezelStyle = .rounded

        headerRow.addArrangedSubview(iconView)
        headerRow.addArrangedSubview(titleStack)
        headerRow.addArrangedSubview(NSView())
        headerRow.addArrangedSubview(testToggleButton)
        rootStack.addArrangedSubview(headerRow)
        headerRow.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        // Current Input Source Card
        statusBadgeBox = makeCardBox()
        let badgeRow = NSStackView()
        badgeRow.orientation = .horizontal
        badgeRow.alignment = .centerY
        badgeRow.translatesAutoresizingMaskIntoConstraints = false

        let badgePrefix = NSTextField(labelWithString: "현재 입력 상태:")
        badgePrefix.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        badgePrefix.textColor = NSColor.secondaryLabelColor

        statusBadgeLabel = NSTextField(labelWithString: "A  English")
        statusBadgeLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        badgeRow.addArrangedSubview(badgePrefix)
        badgeRow.addArrangedSubview(statusBadgeLabel)
        badgeRow.addArrangedSubview(NSView())

        if let boxContent = statusBadgeBox.contentView {
            boxContent.addSubview(badgeRow)
            NSLayoutConstraint.activate([
                badgeRow.topAnchor.constraint(equalTo: boxContent.topAnchor, constant: 8),
                badgeRow.bottomAnchor.constraint(equalTo: boxContent.bottomAnchor, constant: -8),
                badgeRow.leadingAnchor.constraint(equalTo: boxContent.leadingAnchor, constant: 12),
                badgeRow.trailingAnchor.constraint(equalTo: boxContent.trailingAnchor, constant: -12)
            ])
        }
        rootStack.addArrangedSubview(statusBadgeBox)
        statusBadgeBox.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        // 2. Main Features Card
        let settingsBox = makeCardBox()
        let settingsStack = NSStackView()
        settingsStack.orientation = .vertical
        settingsStack.alignment = .leading
        settingsStack.spacing = 10
        settingsStack.translatesAutoresizingMaskIntoConstraints = false

        pcHangulSwitch = NSSwitch()
        pcHangulSwitch.target = self
        pcHangulSwitch.action = #selector(togglePCHangulKey)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "일반 키보드 '한/영' 키 사용",
            subtitle: "PC 키보드의 한/영(Right Alt / Lang1)을 지연 없이 전환 (권한 불필요)",
            control: pcHangulSwitch
        ))

        settingsStack.addArrangedSubview(makeSeparator())

        pcHanjaSwitch = NSSwitch()
        pcHanjaSwitch.target = self
        pcHanjaSwitch.action = #selector(togglePCHanjaKey)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "일반 키보드 '한자' 키 사용",
            subtitle: "PC 한자/Right Ctrl을 macOS 한자 변환(Option+Return)에 연결 (권한 필요)",
            control: pcHanjaSwitch
        ))

        settingsStack.addArrangedSubview(makeSeparator())

        winHomeEndSwitch = NSSwitch()
        winHomeEndSwitch.target = self
        winHomeEndSwitch.action = #selector(toggleWinHomeEnd)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "윈도우식 Home / End 줄 이동 보정",
            subtitle: "줄 맨 앞/뒤 이동 · Shift+선택 · Ctrl+문서 처음/끝 (새로 연 앱부터 적용)",
            control: winHomeEndSwitch
        ))

        settingsStack.addArrangedSubview(makeSeparator())

        winCtrlSwapSwitch = NSSwitch()
        winCtrlSwapSwitch.target = self
        winCtrlSwapSwitch.action = #selector(toggleWinCtrlSwap)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "윈도우식 왼쪽 Ctrl ↔ Win(Command) 교환",
            subtitle: "왼쪽 Ctrl + C/V/Z로 복사·붙여넣기·되돌리기 사용 (권한 불필요)",
            control: winCtrlSwapSwitch
        ))

        settingsStack.addArrangedSubview(makeSeparator())

        winShortcutsSwitch = NSSwitch()
        winShortcutsSwitch.target = self
        winShortcutsSwitch.action = #selector(toggleWinShortcuts)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "윈도우 키(Win) 고유 단축키 사용",
            subtitle: "Win+E(파인더) · Win+D(바탕화면) · Win+L(화면 잠금) · Win+Shift+S(영역 캡처)",
            control: winShortcutsSwitch
        ))

        settingsStack.addArrangedSubview(makeSeparator())

        capsLockSwitch = NSSwitch()
        capsLockSwitch.target = self
        capsLockSwitch.action = #selector(toggleCapsLock)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "Caps Lock을 대문자 전환 전용으로 고정",
            subtitle: "Caps Lock의 한/영 전환 기능을 끄고 원래대로 대문자(A↔a) 잠금으로만 작동",
            control: capsLockSwitch
        ))

        settingsStack.addArrangedSubview(makeSeparator())

        shiftSpaceSwitch = NSSwitch()
        shiftSpaceSwitch.target = self
        shiftSpaceSwitch.action = #selector(toggleShiftSpace)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "Shift + Space 전환 함께 사용",
            subtitle: "윈도우 옛 방식이나 보조 단축키가 필요할 때 활성화",
            control: shiftSpaceSwitch
        ))

        settingsStack.addArrangedSubview(makeSeparator())

        hudSwitch = NSSwitch()
        hudSwitch.target = self
        hudSwitch.action = #selector(toggleHUD)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "화면 전환 알림 (플로팅 HUD)",
            subtitle: "전환 시 화면에 [한] / [A] 배지를 잠깐 표시",
            control: hudSwitch
        ))

        hudCenterCheck = NSButton(checkboxWithTitle: "HUD를 화면 정중앙에 표시 (해제 시 하단 중앙)", target: self, action: #selector(toggleHUDCenter))
        hudCenterCheck.font = NSFont.systemFont(ofSize: 11.5)
        settingsStack.addArrangedSubview(hudCenterCheck)

        settingsStack.addArrangedSubview(makeSeparator())

        launchAtLoginSwitch = NSSwitch()
        launchAtLoginSwitch.target = self
        launchAtLoginSwitch.action = #selector(toggleLaunchAtLogin)
        settingsStack.addArrangedSubview(makeToggleRow(
            title: "맥 로그인 시 자동 실행",
            subtitle: "재부팅 후에도 자동으로 메뉴바에서 한/영 키를 유지",
            control: launchAtLoginSwitch
        ))

        if let boxContent = settingsBox.contentView {
            boxContent.addSubview(settingsStack)
            NSLayoutConstraint.activate([
                settingsStack.topAnchor.constraint(equalTo: boxContent.topAnchor, constant: 12),
                settingsStack.bottomAnchor.constraint(equalTo: boxContent.bottomAnchor, constant: -12),
                settingsStack.leadingAnchor.constraint(equalTo: boxContent.leadingAnchor, constant: 12),
                settingsStack.trailingAnchor.constraint(equalTo: boxContent.trailingAnchor, constant: -12)
            ])
            for view in settingsStack.arrangedSubviews where view !== hudCenterCheck {
                view.widthAnchor.constraint(equalTo: settingsStack.widthAnchor).isActive = true
            }
        }
        rootStack.addArrangedSubview(settingsBox)
        settingsBox.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        // 3. Key Tester & Custom Key Recorder Card
        let recorderBox = makeCardBox()
        let recorderStack = NSStackView()
        recorderStack.orientation = .vertical
        recorderStack.alignment = .leading
        recorderStack.spacing = 8
        recorderStack.translatesAutoresizingMaskIntoConstraints = false

        let recTitle = NSTextField(labelWithString: "내 키보드 '한/영' 키 테스트 및 추가 키 지정")
        recTitle.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        customKeyLabel = NSTextField(labelWithString: "지정된 추가 키: 없음")
        customKeyLabel.font = NSFont.systemFont(ofSize: 12)
        customKeyLabel.textColor = NSColor.secondaryLabelColor

        let recButtons = NSStackView()
        recButtons.orientation = .horizontal
        recButtons.spacing = 8

        recordKeyButton = NSButton(title: "키 눌러서 테스트 / 직접 지정", target: self, action: #selector(toggleRecordKey))
        recordKeyButton.bezelStyle = .rounded

        clearCustomKeyButton = NSButton(title: "추가 키 해제", target: self, action: #selector(clearCustomKey))
        clearCustomKeyButton.bezelStyle = .rounded

        recButtons.addArrangedSubview(recordKeyButton)
        recButtons.addArrangedSubview(clearCustomKeyButton)

        recorderStack.addArrangedSubview(recTitle)
        recorderStack.addArrangedSubview(customKeyLabel)
        recorderStack.addArrangedSubview(recButtons)

        if let boxContent = recorderBox.contentView {
            boxContent.addSubview(recorderStack)
            NSLayoutConstraint.activate([
                recorderStack.topAnchor.constraint(equalTo: boxContent.topAnchor, constant: 10),
                recorderStack.bottomAnchor.constraint(equalTo: boxContent.bottomAnchor, constant: -10),
                recorderStack.leadingAnchor.constraint(equalTo: boxContent.leadingAnchor, constant: 12),
                recorderStack.trailingAnchor.constraint(equalTo: boxContent.trailingAnchor, constant: -12)
            ])
        }
        rootStack.addArrangedSubview(recorderBox)
        recorderBox.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        // 4. System Diagnostics Footer
        let footerStack = NSStackView()
        footerStack.orientation = .vertical
        footerStack.alignment = .leading
        footerStack.spacing = 6

        let hidRow = NSStackView()
        hidRow.orientation = .horizontal
        hidRow.alignment = .centerY
        hidRow.spacing = 8

        hidStatusLabel = NSTextField(labelWithString: "HID 매핑: 확인 중...")
        hidStatusLabel.font = NSFont.systemFont(ofSize: 11)
        hidStatusLabel.textColor = NSColor.secondaryLabelColor
        hidStatusLabel.lineBreakMode = .byTruncatingTail

        let reapplyButton = NSButton(title: "매핑 다시 적용", target: self, action: #selector(reapplyHIDMapping))
        reapplyButton.bezelStyle = .rounded
        reapplyButton.controlSize = .small

        hidRow.addArrangedSubview(hidStatusLabel)
        hidRow.addArrangedSubview(NSView())
        hidRow.addArrangedSubview(reapplyButton)

        let accRow = NSStackView()
        accRow.orientation = .horizontal
        accRow.alignment = .centerY
        accRow.spacing = 8

        accessibilityStatusLabel = NSTextField(labelWithString: "손쉬운 사용 권한: 확인 중...")
        accessibilityStatusLabel.font = NSFont.systemFont(ofSize: 11)
        accessibilityStatusLabel.textColor = NSColor.secondaryLabelColor

        accessibilityButton = NSButton(title: "권한 허용...", target: self, action: #selector(requestAccessibility))
        accessibilityButton.bezelStyle = .rounded
        accessibilityButton.controlSize = .small

        accRow.addArrangedSubview(accessibilityStatusLabel)
        accRow.addArrangedSubview(NSView())
        accRow.addArrangedSubview(accessibilityButton)

        let supportRow = NSStackView()
        supportRow.orientation = .horizontal
        supportRow.alignment = .centerY
        supportRow.spacing = 8

        let freeBadgeLabel = NSTextField(labelWithString: "무료 오픈 유틸리티 • 광고 및 데이터 수집 없음")
        freeBadgeLabel.font = NSFont.systemFont(ofSize: 11)
        freeBadgeLabel.textColor = NSColor.tertiaryLabelColor

        let donateButton = NSButton(title: "☕ 개발자에게 커피 한 잔 후원하기", target: self, action: #selector(openDonationWindow))
        donateButton.bezelStyle = .rounded
        donateButton.controlSize = .small

        supportRow.addArrangedSubview(freeBadgeLabel)
        supportRow.addArrangedSubview(NSView())
        supportRow.addArrangedSubview(donateButton)

        footerStack.addArrangedSubview(hidRow)
        footerStack.addArrangedSubview(accRow)
        footerStack.addArrangedSubview(supportRow)

        rootStack.addArrangedSubview(footerStack)
        footerStack.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true
        hidRow.widthAnchor.constraint(equalTo: footerStack.widthAnchor).isActive = true
        accRow.widthAnchor.constraint(equalTo: footerStack.widthAnchor).isActive = true
        supportRow.widthAnchor.constraint(equalTo: footerStack.widthAnchor).isActive = true
    }

    private func makeCardBox() -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.cornerRadius = 10
        box.borderWidth = 1
        box.borderColor = NSColor.separatorColor.withAlphaComponent(0.5)
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.6)
        box.titlePosition = .noTitle
        return box
    }

    private func makeSeparator() -> NSBox {
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        return sep
    }

    private func makeToggleRow(title: String, subtitle: String, control: NSSwitch) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        let titleField = NSTextField(labelWithString: title)
        titleField.font = NSFont.systemFont(ofSize: 13, weight: .medium)

        let subField = NSTextField(labelWithString: subtitle)
        subField.font = NSFont.systemFont(ofSize: 11)
        subField.textColor = NSColor.secondaryLabelColor

        textStack.addArrangedSubview(titleField)
        textStack.addArrangedSubview(subField)

        row.addArrangedSubview(textStack)
        row.addArrangedSubview(NSView())
        row.addArrangedSubview(control)
        return row
    }

    // MARK: Actions

    @objc private func handleManualToggle() {
        InputSourceManager.shared.toggleInputSource()
        refreshUI()
    }

    @objc private func togglePCHangulKey() {
        AppSettings.shared.pcHangulKeyEnabled = (pcHangulSwitch.state == .on)
        applyHIDAndReload()
    }

    @objc private func togglePCHanjaKey() {
        let on = (pcHanjaSwitch.state == .on)
        AppSettings.shared.pcHanjaKeyEnabled = on
        applyHIDAndReload()
        if on && !HotKeyEngine.shared.isAccessibilityTrusted {
            HotKeyEngine.shared.promptAccessibilityPermission()
        }
    }

    @objc private func toggleWinHomeEnd() {
        let on = (winHomeEndSwitch.state == .on)
        AppSettings.shared.winHomeEndEnabled = on
        _ = HomeEndFixManager.shared.setEnabled(on)
        HUDController.shared.showNotice(
            glyph: on ? "⇄" : "↩",
            caption: on ? "Home/End 보정 켜짐" : "Home/End 기본 복원",
            accentColor: NSColor.white
        )
    }

    @objc private func toggleWinCtrlSwap() {
        let on = (winCtrlSwapSwitch.state == .on)
        AppSettings.shared.winCtrlSwapEnabled = on
        applyHIDAndReload()
        HUDController.shared.showNotice(
            glyph: "⌘⇄⌃",
            caption: on ? "왼쪽 Ctrl 복붙 켜짐" : "왼쪽 Ctrl 기본 복원",
            accentColor: NSColor.white
        )
    }

    @objc private func toggleWinShortcuts() {
        let on = (winShortcutsSwitch.state == .on)
        AppSettings.shared.winShortcutsEnabled = on
        HotKeyEngine.shared.reload()
        HUDController.shared.showNotice(
            glyph: "⊞",
            caption: on ? "Win 단축키 켜짐" : "Win 단축키 꺼짐",
            accentColor: NSColor.white
        )
    }

    @objc private func toggleCapsLock() {
        let uppercaseOnly = (capsLockSwitch.state == .on)
        AppSettings.shared.capsLockUppercaseOnlyEnabled = uppercaseOnly
        CapsLockManager.shared.setUppercaseOnly(uppercaseOnly) { _ in
            HUDController.shared.showNotice(
                glyph: uppercaseOnly ? "⇪" : "한",
                caption: uppercaseOnly ? "Caps Lock 대문자 전용" : "Caps Lock 한/영 허용",
                accentColor: NSColor.white
            )
        }
    }

    @objc private func toggleShiftSpace() {
        AppSettings.shared.shiftSpaceEnabled = (shiftSpaceSwitch.state == .on)
        HotKeyEngine.shared.reload()
    }

    @objc private func toggleHUD() {
        let enabled = (hudSwitch.state == .on)
        AppSettings.shared.hudEnabled = enabled
        hudCenterCheck.isEnabled = enabled
        if enabled {
            let isKor = InputSourceManager.shared.currentSourceInfo().isKorean
            HUDController.shared.show(isKorean: isKor)
        }
    }

    @objc private func toggleHUDCenter() {
        AppSettings.shared.hudCentered = (hudCenterCheck.state == .on)
        let isKor = InputSourceManager.shared.currentSourceInfo().isKorean
        HUDController.shared.show(isKorean: isKor)
    }

    @objc private func toggleLaunchAtLogin() {
        let wantsOn = (launchAtLoginSwitch.state == .on)
        _ = LaunchAgentManager.shared.setEnabled(wantsOn)
        refreshUI()
    }

    @objc private func reapplyHIDMapping() {
        applyHIDAndReload()
    }

    @objc private func openDonationWindow() {
        DonationWindowController.shared.show()
    }

    @objc private func requestAccessibility() {
        HotKeyEngine.shared.promptAccessibilityPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            HotKeyEngine.shared.reload()
            self?.refreshUI()
        }
    }

    @objc private func clearCustomKey() {
        AppSettings.shared.customTriggerKeyCode = -1
        AppSettings.shared.customTriggerModifiers = 0
        AppSettings.shared.customTriggerIsModifier = false
        AppSettings.shared.customTriggerLabel = ""
        HotKeyEngine.shared.reload()
        refreshUI()
    }

    @objc private func toggleRecordKey() {
        if isRecordingKey {
            stopRecordingKey()
            refreshUI()
            return
        }

        isRecordingKey = true
        HotKeyEngine.shared.setPausedForRecording(true)
        recordKeyButton.title = "대기 중... 원하는 키를 누르세요 (취소)"
        customKeyLabel.stringValue = "지금 키보드의 '한/영' 키 또는 원하는 단축키를 1번 누르세요..."

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self, self.isRecordingKey else { return event }

            let keyCode = Int(event.keyCode)
            if event.type == .keyDown && keyCode == kVK_Escape {
                self.stopRecordingKey()
                self.refreshUI()
                return nil
            }

            let isModifier = (event.type == .flagsChanged) || KeyCodeHelper.isModifierKeyCode(keyCode)
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])

            // Ignore pure modifier-up events when recording flagsChanged
            if event.type == .flagsChanged && mods.isEmpty && keyCode != kVK_CapsLock {
                return event
            }

            self.handleCapturedKey(keyCode: keyCode, modifiers: mods, isModifier: isModifier)
            return nil
        }
    }

    private func handleCapturedKey(keyCode: Int, modifiers: NSEvent.ModifierFlags, isModifier: Bool) {
        stopRecordingKey()

        // If the user pressed their PC 한/영 key and it came through as F18 (HID bridge) or JIS_Kana:
        if (keyCode == kVK_F18 || keyCode == kVK_JIS_Kana) && modifiers.isEmpty {
            AppSettings.shared.pcHangulKeyEnabled = true
            applyHIDAndReload()
            customKeyLabel.stringValue = "감지됨: \(KeyCodeHelper.nameForKeyCode(keyCode)) — 기본 한/영 키로 정상 작동합니다!"
            return
        }

        // If the user pressed their PC 한자 key and it came through as F20 (HID bridge) or JIS_Eisu:
        if (keyCode == kVK_F20 || keyCode == kVK_JIS_Eisu) && modifiers.isEmpty {
            AppSettings.shared.pcHanjaKeyEnabled = true
            applyHIDAndReload()
            customKeyLabel.stringValue = "감지됨: \(KeyCodeHelper.nameForKeyCode(keyCode)) — 기본 한자 키로 정상 작동합니다!"
            return
        }

        let label = KeyCodeHelper.describe(keyCode: keyCode, modifiers: modifiers, isModifier: isModifier)
        AppSettings.shared.customTriggerKeyCode = keyCode
        AppSettings.shared.customTriggerModifiers = Int(modifiers.rawValue)
        AppSettings.shared.customTriggerIsModifier = isModifier
        AppSettings.shared.customTriggerLabel = label

        HotKeyEngine.shared.reload()
        refreshUI()

        if isModifier && !HotKeyEngine.shared.isAccessibilityTrusted {
            customKeyLabel.stringValue = "감지됨: \(label) (단독 조합키 동작을 위해 아래 '권한 허용...'이 필요합니다)"
        }
    }

    private func stopRecordingKey() {
        isRecordingKey = false
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
        recordKeyButton.title = "키 눌러서 테스트 / 직접 지정"
        HotKeyEngine.shared.setPausedForRecording(false)
    }

    private func applyHIDAndReload() {
        HIDMapper.shared.applyCurrentSettings { [weak self] _, _ in
            HotKeyEngine.shared.reload()
            self?.refreshUI()
        }
    }
}

// MARK: - Coffee Donation Window Controller

final class DonationWindowController: NSWindowController {
    static let shared = DonationWindowController()

    private var copyFeedbackLabel: NSTextField!

    private var donationURLString: String {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "KSwitchDonationURL") as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return "https://buymeacoffee.com/bli1103"
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "불편해서 내토내만 • KSwitch 응원하기 ☕"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        copyFeedbackLabel.stringValue = ""
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -18)
        ])

        let coffeeIcon = NSTextField(labelWithString: "☕")
        coffeeIcon.font = NSFont.systemFont(ofSize: 38)

        let heading = NSTextField(labelWithString: "불편해서 내토내만 • KSwitch가 도움이 되셨나요?")
        heading.font = NSFont.systemFont(ofSize: 15.5, weight: .bold)

        let desc = NSTextField(wrappingLabelWithString: "광고·추적 없이 무료로 배포되는 초경량 유틸리티입니다.\n아이폰 QR 스캔(Apple Pay) 또는 아래 버튼으로 커피 한 잔 응원해 주세요!")
        desc.font = NSFont.systemFont(ofSize: 12)
        desc.textColor = NSColor.secondaryLabelColor
        desc.alignment = .center

        stack.addArrangedSubview(coffeeIcon)
        stack.addArrangedSubview(heading)
        stack.addArrangedSubview(desc)

        // QR Code Card (supports Resources/donation_qr.png for KakaoPay / Toss)
        let qrCard = NSBox()
        qrCard.boxType = .custom
        qrCard.cornerRadius = 12
        qrCard.borderWidth = 1
        qrCard.borderColor = NSColor.separatorColor.withAlphaComponent(0.6)
        qrCard.fillColor = NSColor.white
        qrCard.titlePosition = .noTitle
        qrCard.translatesAutoresizingMaskIntoConstraints = false

        if let qrPath = Bundle.main.path(forResource: "donation_qr", ofType: "png"),
           let qrImage = NSImage(contentsOfFile: qrPath) {
            let qrView = NSImageView(image: qrImage)
            qrView.imageScaling = .scaleProportionallyUpOrDown
            qrView.translatesAutoresizingMaskIntoConstraints = false
            qrCard.contentView?.addSubview(qrView)
            if let content = qrCard.contentView {
                NSLayoutConstraint.activate([
                    qrView.centerXAnchor.constraint(equalTo: content.centerXAnchor),
                    qrView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                    qrView.widthAnchor.constraint(equalToConstant: 164),
                    qrView.heightAnchor.constraint(equalToConstant: 164),
                    qrCard.widthAnchor.constraint(equalToConstant: 180),
                    qrCard.heightAnchor.constraint(equalToConstant: 180)
                ])
            }
        } else {
            let placeholder = NSTextField(wrappingLabelWithString: "카카오페이 / 토스 QR 자리\n\n배포 전 Resources/donation_qr.png를\n넣으면 QR 코드가 표시됩니다.")
            placeholder.font = NSFont.systemFont(ofSize: 11.5)
            placeholder.textColor = NSColor.darkGray
            placeholder.alignment = .center
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            qrCard.contentView?.addSubview(placeholder)
            if let content = qrCard.contentView {
                NSLayoutConstraint.activate([
                    placeholder.centerXAnchor.constraint(equalTo: content.centerXAnchor),
                    placeholder.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                    placeholder.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 14),
                    placeholder.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -14),
                    qrCard.widthAnchor.constraint(equalToConstant: 240),
                    qrCard.heightAnchor.constraint(equalToConstant: 110)
                ])
            }
        }

        stack.addArrangedSubview(qrCard)

        let qrCaption = NSTextField(labelWithString: "📱 아이폰 카메라로 스캔하여 Buy Me a Coffee 열기")
        qrCaption.font = NSFont.systemFont(ofSize: 11.5, weight: .medium)
        qrCaption.textColor = NSColor.secondaryLabelColor
        stack.addArrangedSubview(qrCaption)

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10

        let openLinkButton = NSButton(title: "☕ Buy Me a Coffee 열기", target: self, action: #selector(openDonationLink))
        openLinkButton.bezelStyle = .rounded
        openLinkButton.keyEquivalent = "\r"

        let copyButton = NSButton(title: "링크 복사", target: self, action: #selector(copyDonationLink))
        copyButton.bezelStyle = .rounded

        let closeButton = NSButton(title: "닫기", target: self, action: #selector(closeWindow))
        closeButton.bezelStyle = .rounded

        buttonRow.addArrangedSubview(openLinkButton)
        buttonRow.addArrangedSubview(copyButton)
        buttonRow.addArrangedSubview(closeButton)
        stack.addArrangedSubview(buttonRow)

        copyFeedbackLabel = NSTextField(labelWithString: "")
        copyFeedbackLabel.font = NSFont.systemFont(ofSize: 11)
        copyFeedbackLabel.textColor = NSColor.systemGreen
        stack.addArrangedSubview(copyFeedbackLabel)
    }

    @objc private func openDonationLink() {
        guard let url = URL(string: donationURLString) else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func copyDonationLink() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(donationURLString, forType: .string)
        copyFeedbackLabel.stringValue = "후원 링크가 클립보드에 복사되었습니다!"
    }

    @objc private func closeWindow() {
        window?.close()
    }
}

// MARK: - App Delegate (Menu Bar Controller)

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var currentStatusMenuItem: NSMenuItem!
    private var pcHangulMenuItem: NSMenuItem!
    private var pcHanjaMenuItem: NSMenuItem!
    private var winHomeEndMenuItem: NSMenuItem!
    private var winCtrlSwapMenuItem: NSMenuItem!
    private var winShortcutsMenuItem: NSMenuItem!
    private var capsLockMenuItem: NSMenuItem!
    private var shiftSpaceMenuItem: NSMenuItem!
    private var hudMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusBar()
        setupWorkspaceObservers()
        HomeEndFixManager.shared.syncWithSettings()
        CapsLockManager.shared.syncWithSettings()

        InputSourceManager.shared.onSourceChanged = { [weak self] info, shouldShowHUD in
            self?.updateStatusBarIcon(isKorean: info.isKorean)
            if shouldShowHUD {
                HUDController.shared.show(isKorean: info.isKorean)
            }
            if DashboardWindowController.shared.window?.isVisible == true {
                DashboardWindowController.shared.refreshUI()
            }
        }

        let current = InputSourceManager.shared.currentSourceInfo()
        updateStatusBarIcon(isKorean: current.isKorean)

        HIDMapper.shared.applyCurrentSettings { _, _ in
            HotKeyEngine.shared.reload()
            DashboardWindowController.shared.refreshUI()
        }

        let lastSeenVersion = UserDefaults.standard.string(forKey: "lastSeenVersion")
        if !AppSettings.shared.hasLaunchedBefore || lastSeenVersion != "1.1.0" {
            AppSettings.shared.hasLaunchedBefore = true
            UserDefaults.standard.set("1.1.0", forKey: "lastSeenVersion")
            DashboardWindowController.shared.showDashboard()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HIDMapper.shared.resetMappingsSync()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        DashboardWindowController.shared.showDashboard()
        return true
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarIcon(isKorean: InputSourceManager.shared.currentSourceInfo().isKorean)

        let menu = NSMenu()

        currentStatusMenuItem = NSMenuItem(title: "현재 입력: 확인 중", action: #selector(menuToggleInputSource), keyEquivalent: "")
        currentStatusMenuItem.target = self
        menu.addItem(currentStatusMenuItem)

        menu.addItem(NSMenuItem.separator())

        pcHangulMenuItem = NSMenuItem(title: "일반 키보드 한/영 키 사용", action: #selector(menuTogglePCHangul), keyEquivalent: "")
        pcHangulMenuItem.target = self
        menu.addItem(pcHangulMenuItem)

        pcHanjaMenuItem = NSMenuItem(title: "일반 키보드 한자 키 사용", action: #selector(menuTogglePCHanja), keyEquivalent: "")
        pcHanjaMenuItem.target = self
        menu.addItem(pcHanjaMenuItem)

        winHomeEndMenuItem = NSMenuItem(title: "윈도우식 Home / End 줄 이동 보정", action: #selector(menuToggleWinHomeEnd), keyEquivalent: "")
        winHomeEndMenuItem.target = self
        menu.addItem(winHomeEndMenuItem)

        winCtrlSwapMenuItem = NSMenuItem(title: "윈도우식 왼쪽 Ctrl ↔ Win 교환", action: #selector(menuToggleWinCtrlSwap), keyEquivalent: "")
        winCtrlSwapMenuItem.target = self
        menu.addItem(winCtrlSwapMenuItem)

        winShortcutsMenuItem = NSMenuItem(title: "윈도우 키 단축키 (Win+E/D/L/Shift+S)", action: #selector(menuToggleWinShortcuts), keyEquivalent: "")
        winShortcutsMenuItem.target = self
        menu.addItem(winShortcutsMenuItem)

        capsLockMenuItem = NSMenuItem(title: "Caps Lock 대문자 전환 전용 고정", action: #selector(menuToggleCapsLock), keyEquivalent: "")
        capsLockMenuItem.target = self
        menu.addItem(capsLockMenuItem)

        shiftSpaceMenuItem = NSMenuItem(title: "Shift + Space 전환", action: #selector(menuToggleShiftSpace), keyEquivalent: "")
        shiftSpaceMenuItem.target = self
        menu.addItem(shiftSpaceMenuItem)

        hudMenuItem = NSMenuItem(title: "화면 전환 알림 (HUD) 표시", action: #selector(menuToggleHUD), keyEquivalent: "")
        hudMenuItem.target = self
        menu.addItem(hudMenuItem)

        menu.addItem(NSMenuItem.separator())

        let dashboardItem = NSMenuItem(title: "설정 및 키 테스트 열기...", action: #selector(menuOpenDashboard), keyEquivalent: ",")
        dashboardItem.target = self
        menu.addItem(dashboardItem)

        let reapplyItem = NSMenuItem(title: "HID 키 매핑 다시 적용", action: #selector(menuReapplyHID), keyEquivalent: "r")
        reapplyItem.target = self
        menu.addItem(reapplyItem)

        let donateItem = NSMenuItem(title: "☕ 개발자에게 커피 한 잔 후원하기...", action: #selector(menuOpenDonation), keyEquivalent: "")
        donateItem.target = self
        menu.addItem(donateItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "KSwitch 종료 (키 매핑 복원)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem.menu = menu
    }

    private func setupWorkspaceObservers() {
        let wsCenter = NSWorkspace.shared.notificationCenter
        wsCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        wsCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    @objc private func handleSystemWake() {
        // Re-apply hidutil mapping after sleep/wake or external keyboard reconnect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            HIDMapper.shared.applyCurrentSettings { _, _ in
                HotKeyEngine.shared.reload()
                DashboardWindowController.shared.refreshUI()
            }
        }
    }

    private func updateStatusBarIcon(isKorean: Bool) {
        guard let button = statusItem.button else { return }
        let title = isKorean ? "한" : "A"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .bold)
        ]
        button.attributedTitle = NSAttributedString(string: title, attributes: attrs)
        button.toolTip = isKorean ? "KSwitch: 한국어 (클릭하여 설정)" : "KSwitch: English (클릭하여 설정)"
    }

    @objc private func menuToggleInputSource() {
        InputSourceManager.shared.toggleInputSource()
    }

    @objc private func menuTogglePCHangul() {
        AppSettings.shared.pcHangulKeyEnabled.toggle()
        HIDMapper.shared.applyCurrentSettings { _, _ in
            HotKeyEngine.shared.reload()
            DashboardWindowController.shared.refreshUI()
        }
    }

    @objc private func menuTogglePCHanja() {
        AppSettings.shared.pcHanjaKeyEnabled.toggle()
        HIDMapper.shared.applyCurrentSettings { _, _ in
            HotKeyEngine.shared.reload()
            DashboardWindowController.shared.refreshUI()
        }
        if AppSettings.shared.pcHanjaKeyEnabled && !HotKeyEngine.shared.isAccessibilityTrusted {
            HotKeyEngine.shared.promptAccessibilityPermission()
        }
    }

    @objc private func menuToggleWinHomeEnd() {
        AppSettings.shared.winHomeEndEnabled.toggle()
        _ = HomeEndFixManager.shared.setEnabled(AppSettings.shared.winHomeEndEnabled)
        DashboardWindowController.shared.refreshUI()
    }

    @objc private func menuToggleWinCtrlSwap() {
        AppSettings.shared.winCtrlSwapEnabled.toggle()
        HIDMapper.shared.applyCurrentSettings { _, _ in
            HotKeyEngine.shared.reload()
            DashboardWindowController.shared.refreshUI()
        }
    }

    @objc private func menuToggleWinShortcuts() {
        AppSettings.shared.winShortcutsEnabled.toggle()
        HotKeyEngine.shared.reload()
        DashboardWindowController.shared.refreshUI()
    }

    @objc private func menuToggleCapsLock() {
        AppSettings.shared.capsLockUppercaseOnlyEnabled.toggle()
        CapsLockManager.shared.setUppercaseOnly(AppSettings.shared.capsLockUppercaseOnlyEnabled) { _ in
            DashboardWindowController.shared.refreshUI()
        }
    }

    @objc private func menuToggleShiftSpace() {
        AppSettings.shared.shiftSpaceEnabled.toggle()
        HotKeyEngine.shared.reload()
        DashboardWindowController.shared.refreshUI()
    }

    @objc private func menuToggleHUD() {
        AppSettings.shared.hudEnabled.toggle()
        if AppSettings.shared.hudEnabled {
            HUDController.shared.show(isKorean: InputSourceManager.shared.currentSourceInfo().isKorean)
        }
        DashboardWindowController.shared.refreshUI()
    }

    @objc private func menuOpenDashboard() {
        DashboardWindowController.shared.showDashboard()
    }

    @objc private func menuReapplyHID() {
        HIDMapper.shared.applyCurrentSettings { _, _ in
            HotKeyEngine.shared.reload()
            DashboardWindowController.shared.refreshUI()
        }
    }

    @objc private func menuOpenDonation() {
        DonationWindowController.shared.show()
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        let info = InputSourceManager.shared.currentSourceInfo()
        currentStatusMenuItem.title = info.isKorean
            ? "현재: 한국어 (\(info.name)) — 클릭 시 영어로 전환"
            : "현재: English (\(info.name)) — 클릭 시 한국어로 전환"

        let settings = AppSettings.shared
        pcHangulMenuItem.state = settings.pcHangulKeyEnabled ? .on : .off
        pcHanjaMenuItem.state = settings.pcHanjaKeyEnabled ? .on : .off
        winHomeEndMenuItem.state = settings.winHomeEndEnabled ? .on : .off
        winCtrlSwapMenuItem.state = settings.winCtrlSwapEnabled ? .on : .off
        winShortcutsMenuItem.state = settings.winShortcutsEnabled ? .on : .off
        capsLockMenuItem.state = settings.capsLockUppercaseOnlyEnabled ? .on : .off
        shiftSpaceMenuItem.state = settings.shiftSpaceEnabled ? .on : .off
        hudMenuItem.state = settings.hudEnabled ? .on : .off
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
