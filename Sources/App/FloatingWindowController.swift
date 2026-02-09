import SwiftUI
import AppKit

final class FloatingWindowController: NSWindowController, NSWindowDelegate {
    private let clipboardManager: ClipboardManager
    private let hotkeyManager: HotkeyManager
    private var previousApp: NSRunningApplication?
    
    private let windowWidth: CGFloat = 320
    private let windowMaxHeight: CGFloat = 400
    private let itemHeight: CGFloat = 52
    private let headerHeight: CGFloat = 50
    
    init(clipboardManager: ClipboardManager, hotkeyManager: HotkeyManager) {
        self.clipboardManager = clipboardManager
        self.hotkeyManager = hotkeyManager
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        capturePreviousApp()
        createWindowIfNeeded()
        showWindow()
    }
    
    private func createWindowIfNeeded() {
        guard self.window == nil else { return }
        
        let contentView = ClipboardWindowView(
            clipboardManager: clipboardManager,
            hotkeyManager: hotkeyManager,
            onClose: { [weak self] in
                self?.hide()
            },
            onPasteRequested: { [weak self] item in
                self?.pasteAndDismiss(item)
            }
        )
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: headerHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .popUpMenu
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.contentView = hostingController.view
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor)
        ])
        
        self.window = window
        
        centerWindow()
    }
    
    private func centerWindow() {
        guard let window = self.window else { return }
        
        let itemCount = clipboardManager.items.count
        let windowHeight = headerHeight + CGFloat(itemCount) * itemHeight
        let displayHeight = min(windowHeight, windowMaxHeight)
        
        let windowSize = CGSize(width: windowWidth, height: displayHeight)
        window.setContentSize(windowSize)
        
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen = screen else { return }
        
        let screenFrame = screen.visibleFrame
        let originX = screenFrame.midX - windowWidth / 2
        let originY = screenFrame.midY - displayHeight / 2
        
        window.setFrameOrigin(CGPoint(x: originX, y: originY))
    }
    
    private func showWindow() {
        guard let window = self.window else { return }
        
        centerWindow()
        
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        
        hotkeyManager.isWindowVisible = true
    }
    
    func hide() {
        window?.orderOut(nil)
        hotkeyManager.isWindowVisible = false
    }
    
    func updateSize() {
        guard hotkeyManager.isWindowVisible else { return }
        centerWindow()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide()
        return false
    }

    private func capturePreviousApp() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.bundleIdentifier == Bundle.main.bundleIdentifier {
            previousApp = nil
        } else {
            previousApp = frontmost
        }
    }

    private func pasteAndDismiss(_ item: ClipboardItem) {
        hide()
        let targetApp = previousApp
        previousApp = nil
        
        if let targetApp = targetApp {
            targetApp.activate(options: [.activateIgnoringOtherApps])
        } else {
            NSApp.hide(nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.clipboardManager.paste(item: item)
        }
    }
}
