import Foundation

struct HotkeySettings: Codable {
    var hotkey1: HotkeyConfig
    
    struct HotkeyConfig: Codable, Equatable {
        var keyCode: Int
        var modifierFlags: Int
        var isEnabled: Bool
        
        static let control = 524288
        static let option = 262144
        static let command = 65536
        static let shift = 1048576
        
        static let default1 = HotkeyConfig(keyCode: 9, modifierFlags: 524288, isEnabled: true)
        
        var displayName: String {
            if !isEnabled {
                return "未设置"
            }
            let modifiers = parseModifierFlags()
            let key = keyName
            if modifiers.isEmpty {
                return key
            }
            return modifiers + "+" + key
        }
        
        private var keyName: String {
            switch keyCode {
            case 0: return "A"
            case 1: return "S"
            case 2: return "D"
            case 3: return "F"
            case 4: return "H"
            case 5: return "G"
            case 6: return "Z"
            case 7: return "X"
            case 8: return "C"
            case 9: return "V"
            case 11: return "B"
            case 12: return "Q"
            case 13: return "W"
            case 14: return "E"
            case 15: return "R"
            case 16: return "Y"
            case 17: return "T"
            case 18: return "1"
            case 19: return "2"
            case 20: return "3"
            case 21: return "4"
            case 22: return "6"
            case 23: return "5"
            case 25: return "9"
            case 26: return "7"
            case 27: return "-"
            case 28: return "Enter"
            case 29: return "8"
            case 30: return "0"
            case 31: return "]"
            case 33: return ";"
            case 34: return "K"
            case 35: return "L"
            case 37: return ","
            case 38: return "/"
            case 39: return "N"
            case 40: return "M"
            case 41: return "."
            case 42: return "Tab"
            case 43: return "Space"
            case 44: return "\\"
            case 45: return "="
            case 46: return "-"
            case 47: return "["
            case 48: return "'"
            case 49: return "`"
            case 50: return ","
            case 51: return "."
            case 53: return "Esc"
            case 55: return "Cmd"
            case 56: return "Shift"
            case 57: return "Caps"
            case 58: return "Opt"
            case 59: return "Ctrl"
            case 60: return "RShift"
            case 61: return "ROpt"
            case 62: return "RCtrl"
            case 64: return "F4"
            case 65: return "F5"
            case 66: return "F6"
            case 67: return "F7"
            case 71: return "F8"
            case 72: return "F9"
            case 73: return "F10"
            case 75: return "F11"
            case 76: return "F12"
            default: return "Key\(keyCode)"
            }
        }
        
        private func parseModifierFlags() -> String {
            var parts: [String] = []
            if modifierFlags & 65536 != 0 { parts.append("⌘") }
            if modifierFlags & 262144 != 0 { parts.append("⌥") }
            if modifierFlags & 1048576 != 0 { parts.append("⇧") }
            if modifierFlags & 524288 != 0 { parts.append("⌃") }
            return parts.joined()
        }
    }
    
    static let defaultSettings = HotkeySettings(
        hotkey1: HotkeyConfig(keyCode: 9, modifierFlags: 524288, isEnabled: true)
    )
}
