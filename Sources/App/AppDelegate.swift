import SwiftUI
import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var floatingWindowController: FloatingWindowController?
    private var settingsWindowController: NSWindowController?
    
    private let clipboardManager = ClipboardManager.shared
    private var hotkeyManager: HotkeyManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        fputs("[AppDelegate] applicationDidFinishLaunching\n", stderr)
        fflush(stderr)
        
        hotkeyManager = HotkeyManager.shared
        
        fputs("[AppDelegate] Initializing components...\n", stderr)
        fflush(stderr)
        
        setupStatusBar()
        setupNotifications()
        setupMenuBar()
        checkAutoLaunch()
        
        NSApp.setActivationPolicy(.accessory)
        
        fputs("[AppDelegate] App launched successfully\n", stderr)
        fflush(stderr)
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem.button else { return }
        
        button.image = loadAppIcon()
        button.image?.size = NSSize(width: 20, height: 20)
        button.title = ""
        button.target = self
        button.action = #selector(statusBarClicked)
        
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        floatingWindowController = FloatingWindowController(
            clipboardManager: clipboardManager,
            hotkeyManager: hotkeyManager
        )
    }
    
    private func loadAppIcon() -> NSImage? {
        if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png"),
           let image = NSImage(contentsOfFile: iconPath) {
            let resized = NSImage(size: NSSize(width: 20, height: 20))
            resized.lockFocus()
            image.draw(in: NSRect(x: 0, y: 0, width: 20, height: 20), from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height), operation: .copy, fraction: 1.0)
            resized.unlockFocus()
            return resized
        }
        return NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "剪贴板工具")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showWindow),
            name: .showClipboardWindow,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideWindow),
            name: .hideClipboardWindow,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateWindowSize),
            name: .clipboardDidUpdate,
            object: nil
        )
    }
    
    private func setupMenuBar() {
        let menu = NSMenu()
        
        let windowItem = NSMenuItem(
            title: "📋 显示剪贴板窗口",
            action: #selector(showWindow),
            keyEquivalent: ""
        )
        menu.addItem(windowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: "⚙️ 快捷键设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = [.command]
        menu.addItem(settingsItem)
        
        let autoLaunchItem = NSMenuItem(
            title: "🚀 开机自启动",
            action: #selector(toggleAutoLaunch),
            keyEquivalent: ""
        )
        autoLaunchItem.state = UserDefaults.standard.bool(forKey: "autoLaunchEnabled") ? .on : .off
        menu.addItem(autoLaunchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(
            title: "ℹ️ 关于",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "❌ 退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    private func checkAutoLaunch() {
        if UserDefaults.standard.object(forKey: "autoLaunchEnabled") == nil {
            UserDefaults.standard.set(false, forKey: "autoLaunchEnabled")
        }
    }
    
    @objc private func statusBarClicked() {
        if hotkeyManager.isWindowVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    @objc private func showWindow() {
        floatingWindowController?.show()
    }
    
    @objc private func hideWindow() {
        floatingWindowController?.hide()
    }
    
    @objc private func updateWindowSize() {
        if hotkeyManager.isWindowVisible {
            floatingWindowController?.updateSize()
        }
    }
    
    @objc private func openSettings() {
        if let existingController = settingsWindowController,
           let window = existingController.window,
           window.isVisible {
            window.orderFrontRegardless()
            return
        }
        
        let settingsView = SettingsView(hotkeyManager: hotkeyManager)
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "⚙️ 剪贴板工具设置"
        settingsWindow.contentViewController = NSHostingController(rootView: settingsView)
        settingsWindow.center()
        settingsWindow.level = .floating
        
        settingsWindowController = NSWindowController(window: settingsWindow)
        settingsWindowController?.showWindow(nil)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func toggleAutoLaunch() {
        let currentlyEnabled = UserDefaults.standard.bool(forKey: "autoLaunchEnabled")
        let newState = !currentlyEnabled
        
        do {
            if newState {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            UserDefaults.standard.set(newState, forKey: "autoLaunchEnabled")
            
            if let menu = statusItem.menu {
                for item in menu.items where item.action == #selector(toggleAutoLaunch) {
                    item.state = newState ? .on : .off
                }
            }
        } catch {
            print("Failed to update launch status: \(error)")
            let alert = NSAlert()
            alert.messageText = "设置失败"
            alert.informativeText = "无法更新自启动设置，请检查系统偏好设置中的隐私权限。"
            alert.runModal()
        }
    }
    
    @objc private func showAbout() {
        let aboutView = AboutView()
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.title = "关于剪贴板工具"
        aboutWindow.contentViewController = NSHostingController(rootView: aboutView)
        aboutWindow.center()
        aboutWindow.level = .floating
        aboutWindow.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        ClipboardManager.shared.stopMonitoring()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        hideWindow()
    }
}
