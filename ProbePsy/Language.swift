import Foundation

/// All app-authored visible copy is maintained in one bundled language file.
struct LanguageCatalog {
    static let shared = LanguageCatalog()
    let strings: [String: [String: String]]
    private init() {
        guard let url = Bundle.main.url(forResource: "Languages", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            preconditionFailure("Missing or invalid Languages.json")
        }
        strings = value
    }
    func text(_ key: String, language: String) -> String {
        guard let result = strings[language]?[key] else {
            assertionFailure("Missing translation: \(language).\(key)")
            return strings["en"]?[key] ?? key
        }
        return result
    }
}

/// Limited offline phrase matching, NOT a clinical risk assessment or AI.
/// Check all supported languages regardless of the chosen UI language.
enum SafetySignals {
    static func containsSignal(_ text: String) -> Bool {
        let normalized = normalize(text)
        return LanguageCatalog.shared.strings.values.contains { language in
            (language["riskPhrases"] ?? "").split(separator: "|").contains {
                normalized.contains(normalize(String($0)))
            }
        }
    }
    static func normalize(_ text: String) -> String {
        text.replacingOccurrences(of: "ı", with: "i")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: " ")
    }
}
