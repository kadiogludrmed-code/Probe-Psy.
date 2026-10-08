import Foundation
import Observation
import CryptoKit
import Security

struct MoodEntry: Codable, Identifiable {
    var id = UUID()
    let timestamp: Date
    let timeZoneID: String
    let mood: Int
    let note: String
}

struct LocalState: Codable {
    var schemaVersion = 1
    var language: String?
    var entries: [MoodEntry] = []
    var needsHelp = false
}

/// No network, analytics, CloudKit, account identifiers, or UserDefaults.
/// The encryption key is non-synchronizing and bound to this device.
struct LocalVault {
    enum Failure: Error { case keychain, invalidState, missingKey }
    private var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrivateMood", isDirectory: true)
    }
    private var file: URL { directory.appendingPathComponent("state.sealed") }

    private func key(create: Bool) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "ProbePsy",
            kSecAttrAccount as String: "local-vault-v1",
            kSecAttrSynchronizable as String: false
        ]
        var readQuery = query
        readQuery[kSecReturnData as String] = true
        readQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(readQuery as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return SymmetricKey(data: data)
        }
        guard status == errSecItemNotFound else { throw Failure.keychain }
        guard create else { throw Failure.missingKey }
        let generated = SymmetricKey(size: .bits256)
        var insert = query
        insert[kSecValueData as String] = generated.withUnsafeBytes { Data($0) }
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw Failure.keychain }
        return generated
    }

    func read() throws -> LocalState {
        guard FileManager.default.fileExists(atPath: file.path) else { return LocalState() }
        let bytes = try Data(contentsOf: file)
        let plaintext = try AES.GCM.open(AES.GCM.SealedBox(combined: bytes), using: key(create: false))
        let value = try JSONDecoder().decode(LocalState.self, from: plaintext)
        guard value.schemaVersion == 1,
              value.language.map({ ["de", "en", "tr"].contains($0) }) ?? true,
              value.entries.allSatisfy({ (1...10).contains($0.mood) }) else { throw Failure.invalidState }
        return value
    }

    func write(_ value: LocalState) throws {
        var folder = directory
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete])
        var flags = URLResourceValues()
        flags.isExcludedFromBackup = true
        try folder.setResourceValues(flags)
        let payload = try JSONEncoder().encode(value)
        let sealed = try AES.GCM.seal(payload, using: key(create: true))
        guard let bytes = sealed.combined else { throw Failure.invalidState }
        try bytes.write(to: file, options: [.atomic, .completeFileProtection])
        var savedFile = file
        try savedFile.setResourceValues(flags)
    }
}

@MainActor @Observable
final class LocalStore {
    private(set) var state = LocalState()
    private(set) var ready = false
    var storageError = false
    private let vault = LocalVault()

    init() { reload() }

    func reload() {
        do {
            state = try vault.read()
            ready = true
            storageError = false
        } catch {
            // Never replace unreadable or temporarily locked data with empty data.
            ready = false
            storageError = true
        }
    }

    @discardableResult private func commit(_ next: LocalState) -> Bool {
        guard ready else { storageError = true; return false }
        do {
            try vault.write(next)
            state = next
            storageError = false
            return true
        } catch {
            storageError = true
            return false
        }
    }

    func chooseLanguage(_ code: String) {
        guard ["de", "en", "tr"].contains(code) else { return }
        var next = state
        next.language = code
        commit(next)
    }

    func save(mood: Int, note: String) -> Bool {
        guard (1...10).contains(mood), note.count <= 4000 else { return false }
        var next = state
        next.entries.append(MoodEntry(timestamp: Date(), timeZoneID: TimeZone.current.identifier,
                                      mood: mood, note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
        return commit(next)
    }

    func flagHelp() {
        guard !state.needsHelp else { return }
        var next = state
        next.needsHelp = true
        if !commit(next) { state.needsHelp = true } // Remain visible even if disk fails.
    }

    func acknowledgeHelp() {
        var next = state
        next.needsHelp = false
        commit(next)
    }
}
