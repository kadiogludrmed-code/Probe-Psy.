import SwiftUI

struct RootView: View {
    @Bindable var store: LocalStore
    @Environment(\.openURL) private var openURL
    @State private var mood = 5.0
    @State private var note = ""
    @State private var saved = false
    @State private var languagesPresented = false
    @State private var callFailed = false
    @FocusState private var editing: Bool

    private var language: String { store.state.language ?? "de" }
    private func t(_ key: String) -> String { LanguageCatalog.shared.text(key, language: language) }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.cyan.opacity(0.15), .indigo.opacity(0.10), Color(.systemBackground)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                if !store.ready {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield").font(.largeTitle)
                        Text(t("storageError"))
                        Button(t("retry")) { store.reload() }.buttonStyle(.borderedProminent)
                    }.padding()
                } else if store.state.language == nil {
                    languagePicker
                } else {
                    entryForm
                }
            }
            .navigationTitle(t("appName"))
            .toolbar {
                if store.state.language != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { languagesPresented = true } label: {
                            Image(systemName: "globe")
                        }.accessibilityLabel(t("language"))
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(t("done")) { editing = false }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { helpBar }
            .sheet(isPresented: $languagesPresented) {
                NavigationStack {
                    languagePicker
                        .toolbar { ToolbarItem(placement: .confirmationAction) {
                            Button(t("done")) { languagesPresented = false }
                        }}
                }
            }
            .alert(t("storageTitle"), isPresented: $store.storageError) {
                Button(t("done"), role: .cancel) { }
            } message: { Text(t("storageError")) }
            .alert(t("callTitle"), isPresented: $callFailed) {
                Button(t("done"), role: .cancel) { }
            } message: { Text(t("callError")) }
        }
        .tint(.teal)
    }

    private var languagePicker: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 46)).foregroundStyle(.teal)
                Text(t("chooseLanguage")).font(.title2.bold()).multilineTextAlignment(.center)
                ForEach(["de", "en", "tr"], id: \.self) { code in
                    Button {
                        store.chooseLanguage(code)
                        if !store.storageError { languagesPresented = false }
                    } label: {
                        Text(LanguageCatalog.shared.text("languageName", language: code))
                            .font(.title3.weight(.medium)).frame(maxWidth: .infinity).padding(18)
                            .modifier(GlassSurface())
                    }.buttonStyle(.plain)
                }
                Text(t("audience")).font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }
    }

    private var entryForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(t("question")).font(.largeTitle.bold())
                    Text(t("intro")).foregroundStyle(.secondary)
                }
                VStack(spacing: 18) {
                    Image(systemName: "circle.lefthalf.filled").font(.system(size: 42)).foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    Text("\(Int(mood)) / 10").font(.system(.largeTitle, design: .rounded).bold())
                        .monospacedDigit()
                    Slider(value: $mood, in: 1...10, step: 1)
                        .accessibilityLabel(t("mood"))
                        .accessibilityValue("\(Int(mood)) / 10")
                    HStack {
                        Text(t("low"))
                        Spacer()
                        Text(t("high"))
                    }.font(.caption).foregroundStyle(.secondary)
                }.padding(24).frame(maxWidth: .infinity)
                    .background(.background, in: RoundedRectangle(cornerRadius: 28))

                VStack(alignment: .leading, spacing: 8) {
                    Text(t("note")).font(.headline)
                    TextField(t("notePrompt"), text: $note, axis: .vertical)
                        .lineLimit(4...8).focused($editing)
                        .autocorrectionDisabled().textInputAutocapitalization(.sentences)
                        .padding(16).background(.background, in: RoundedRectangle(cornerRadius: 18))
                        .onChange(of: note) { _, newValue in
                            saved = false
                            // Inspect before truncating so a pasted signal at the end isn't skipped.
                            if SafetySignals.containsSignal(newValue) { store.flagHelp() }
                            if newValue.count > 4000 { note = String(newValue.prefix(4000)) }
                        }
                    Text(t("privacy")).font(.caption).foregroundStyle(.secondary)
                }
                Button {
                    editing = false
                    if SafetySignals.containsSignal(note) { store.flagHelp() }
                    if store.save(mood: Int(mood), note: note) {
                        note = ""
                        saved = true
                    }
                } label: {
                    Label(t("save"), systemImage: "checkmark.circle.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }.buttonStyle(.borderedProminent).controlSize(.large)

                if saved {
                    Label(t("saved"), systemImage: "checkmark.shield")
                        .foregroundStyle(.teal).accessibilityAddTraits(.updatesFrequently)
                }
                if let last = store.state.entries.last {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(t("lastEntry")).font(.headline)
                        Text(last.timestamp, format: .dateTime.day().month().year().hour().minute())
                            .foregroundStyle(.secondary)
                        Text("\(last.mood) / 10").font(.title2.bold())
                        if !last.note.isEmpty { Text(last.note) }
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background, in: RoundedRectangle(cornerRadius: 20))
                }
                Text(t("disclaimer")).font(.footnote).foregroundStyle(.secondary)
                Text(t("safetyLimit")).font(.caption).foregroundStyle(.secondary)
            }.padding(22)
        }.scrollDismissesKeyboard(.interactively)
    }

    private var helpBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.state.needsHelp {
                Text(t("crisisTitle")).font(.headline).foregroundStyle(.red)
                Text(t("crisisBody")).font(.subheadline)
                Button(t("helpSought")) { store.acknowledgeHelp() }
                    .font(.subheadline).buttonStyle(.bordered)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { emergencyButton; helplineButton }
                VStack(alignment: .leading, spacing: 8) { emergencyButton; helplineButton }
            }
            Text(t("helpRegion")).font(.caption2).foregroundStyle(.secondary)
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
    }

    private var emergencyButton: some View {
        Button { call("112") } label: {
            Label(t("emergency"), systemImage: "phone.fill").font(.headline)
        }.tint(.red).buttonStyle(.borderedProminent)
    }
    private var helplineButton: some View {
        Button(t("helpline")) { call("08001110111") }.buttonStyle(.bordered)
    }
    private func call(_ number: String) {
        guard let url = URL(string: "tel:\(number)") else { return }
        openURL(url) { accepted in if !accepted { callFailed = true } }
    }
}

private struct GlassSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22))
        } else if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        }
    }
}
