import Foundation
import AppKit
import Carbon

final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var isMonitoring = false
    
    private let maxItems = 100
    private var timer: Timer?
    private var changeCount: Int = 0
    
    private let userDefaultsKey = "clipboard_items"
    private let userDefaultsChangeCountKey = "clipboard_change_count"
    
    private init() {
        loadItems()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        changeCount = UserDefaults.standard.integer(forKey: userDefaultsChangeCountKey)
        isMonitoring = true
        
        DispatchQueue.main.async { [weak self] in
            self?.checkClipboard()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkClipboard()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard let string = pasteboard.string(forType: .string) else {
            return
        }
        
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != changeCount && !string.isEmpty {
            changeCount = currentChangeCount
            UserDefaults.standard.set(changeCount, forKey: userDefaultsChangeCountKey)
            
            addItem(string)
        }
    }
    
    private func addItem(_ content: String) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else { return }
        
        let existingIndex = items.firstIndex { $0.content == trimmedContent }
        
        if let existingIndex = existingIndex {
            let existingItem = items[existingIndex]
            let newItem = ClipboardItem(id: existingItem.id, content: trimmedContent, timestamp: Date())
            items.remove(at: existingIndex)
            items.insert(newItem, at: 0)
        } else {
            let newItem = ClipboardItem(content: trimmedContent)
            items.insert(newItem, at: 0)
        }
        
        while items.count > maxItems {
            items.removeLast()
        }
        
        saveItems()
        
        NotificationCenter.default.post(name: .clipboardDidUpdate, object: nil)
    }
    
    func paste(item: ClipboardItem) {
        pasteContent(item.content)
    }
    
    func typeText(_ text: String) {
        fputs("[ClipboardManager] typeText called with: \(String(text.prefix(30)))\n", stderr)
        fflush(stderr)
        
        fputs("[ClipboardManager] Starting typing simulation...\n", stderr)
        fflush(stderr)
        
        for char in text {
            if char.isNewline {
                postKeyEvent(36, keyDown: true)
                Thread.sleep(forTimeInterval: 0.001)
                postKeyEvent(36, keyDown: false)
            } else if char == " " {
                postKeyEvent(49, keyDown: true)
                Thread.sleep(forTimeInterval: 0.001)
                postKeyEvent(49, keyDown: false)
            } else {
                let chars = String(char).lowercased()
                for c in chars {
                    if let keyCode = keyCodeForCharacter(c) {
                        postKeyEvent(Int(keyCode), keyDown: true)
                        Thread.sleep(forTimeInterval: 0.001)
                        postKeyEvent(Int(keyCode), keyDown: false)
                    }
                }
            }
            Thread.sleep(forTimeInterval: 0.001)
        }
        
        fputs("[ClipboardManager] Typing simulation complete\n", stderr)
        fflush(stderr)
    }
    
    private func postKeyEvent(_ keyCode: Int, keyDown: Bool) {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return
        }
        
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: keyDown) else {
            return
        }
        
        event.post(tap: .cgSessionEventTap)
    }
    
    private func pasteContent(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.simulatePaste()
        }
        
        if let index = self.items.firstIndex(where: { $0.content == content }) {
            let updatedItem = ClipboardItem(id: self.items[index].id, content: content, timestamp: Date())
            self.items.remove(at: index)
            self.items.insert(updatedItem, at: 0)
            self.saveItems()
        }
    }
    
    private func simulatePaste() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        
        let keyCode = CGKeyCode(9)
        let downEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        downEvent?.flags = .maskCommand
        downEvent?.post(tap: .cgSessionEventTap)
        
        let upEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        upEvent?.post(tap: .cgSessionEventTap)
    }
    
    private func simulateTyping(_ text: String) {
    }
    
    private func keyCodeForCharacter(_ char: Character) -> CGKeyCode? {
        let charMap: [Character: CGKeyCode] = [
            "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4,
            "i": 34, "j": 38, "k": 40, "l": 37, "m": 39, "n": 45, "o": 31, "p": 35,
            "q": 12, "r": 15, "s": 1, "t": 17, "u": 32, "v": 9, "w": 13, "x": 7,
            "y": 16, "z": 6,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22,
            "7": 26, "8": 28, "9": 25,
            "-": 27, "=": 24, "[": 33, "]": 30, "\\": 42, ";": 39, "'": 47,
            ",": 43, ".": 47, "/": 44, "`": 50
        ]
        return charMap[char]
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
        NotificationCenter.default.post(name: .clipboardDidUpdate, object: nil)
    }
    
    func clearAll() {
        items.removeAll()
        saveItems()
        NotificationCenter.default.post(name: .clipboardDidUpdate, object: nil)
    }
    
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }
    
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            items = []
            return
        }
        
        do {
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard items: \(error)")
            items = []
        }
    }
}

extension Notification.Name {
    static let clipboardDidUpdate = Notification.Name("clipboardDidUpdate")
}
