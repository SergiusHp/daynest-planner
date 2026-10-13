import SwiftUI
import UserNotifications

/// Шторка «Новий план» / «Змінити план». Закривається й свайпом униз (нативно).
struct PlanSheet: View {
    let target: SheetTarget
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var day = Date()
    @State private var hasTime = false
    @State private var time = Date()
    @State private var remind = 0
    @State private var showError = false
    @State private var confirmDelete = false
    @State private var notifyStatus: UNAuthorizationStatus = .notDetermined
    @FocusState private var textFocused: Bool

    private var editing: Plan? { if case .edit(let p) = target { return p } else { return nil } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image("CatWink")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72)
                        .padding(.leading, -6)
                        .accessibilityHidden(true)
                    Text(editing == nil ? "Новий план" : "Змінити план")
                        .font(.nunito(21, .extraBold, relativeTo: .title2))
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                }

                field("Що плануєш зробити?") {
                    TextField("Наприклад: прочитати 10 сторінок книги", text: $text, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.nunito(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .focused($textFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(minHeight: 80, alignment: .topLeading)
                        .background(inputBackground(focused: textFocused))
                        .accessibilityIdentifier("planText")
                        .onChange(of: text) { _, _ in if showError { showError = false } }
                }
                if showError {
                    Text("Напиши, що саме плануєш.")
                        .font(.nunito(13, .extraBold))
                        .foregroundStyle(Theme.error)
                        .padding(.top, 4)
                }

                HStack(alignment: .top, spacing: 12) {
                    field("День") {
                        DatePicker("День", selection: $day, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .padding(.horizontal, 6)
                            .background(inputBackground(focused: false))
                    }
                    field("Час (необовʼязково)") {
                        HStack(spacing: 4) {
                            if hasTime {
                                DatePicker("Час", selection: $time, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                Spacer(minLength: 0)
                                Button {
                                    withAnimation(.easeOut(duration: 0.2)) { hasTime = false; remind = 0 }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Theme.inkFaint)
                                        .frame(width: 36, height: 44)
                                }
                                .accessibilityLabel("Прибрати час")
                            } else {
                                Button {
                                    withAnimation(.easeOut(duration: 0.2)) { hasTime = true }
                                } label: {
                                    Label("Додати час", systemImage: "clock")
                                        .font(.nunito(15, .bold))
                                        .foregroundStyle(Theme.inkSoft)
                                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                                        .padding(.leading, 6)
                                }
                                .accessibilityIdentifier("addTime")
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .padding(.horizontal, 6)
                        .background(inputBackground(focused: false))
                    }
                }

                if hasTime {
                    field("Нагадування") {
                        Menu {
                            Picker("Нагадування", selection: $remind) {
                                ForEach(ReminderOption.allCases) { o in Text(o.title).tag(o.rawValue) }
                            }
                        } label: {
                            HStack {
                                Text(ReminderOption(rawValue: remind)?.title ?? "Без нагадування")
                                    .font(.nunito(16, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.brown)
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 52)
                            .background(inputBackground(focused: false))
                        }
                        .accessibilityIdentifier("remindPicker")
                    }
                    if remind > 0 {
                        Text(remindNote)
                            .font(.nunito(12, .semibold, relativeTo: .caption))
                            .foregroundStyle(Theme.inkMuted)
                            .padding(.top, 6)
                    }
                }

                HStack(spacing: 12) {
                    Button("Скасувати") { dismiss() }
                        .buttonStyle(LedgeButtonStyle(fill: .clear, text: Theme.inkSoft, ledge: .clear))
                        .frame(maxWidth: .infinity)
                    Button(editing == nil ? "Додати" : "Зберегти", action: save)
                        .buttonStyle(.primaryLedge)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(1)
                        .accessibilityIdentifier("savePlan")
                }
                .padding(.top, 24)

                if editing != nil {
                    Button("Видалити план", role: .destructive) { confirmDelete = true }
                        .font(.nunito(14, .extraBold))
                        .foregroundStyle(Theme.error)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.top, 8)
                        .confirmationDialog("Видалити цей план?", isPresented: $confirmDelete, titleVisibility: .visible) {
                            Button("Видалити", role: .destructive) {
                                if let p = editing { store.delete(p.id) }
                                dismiss()
                            }
                            Button("Скасувати", role: .cancel) {}
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.day)
        .presentationDetents([.fraction(0.68), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(Theme.day)
        .onAppear(perform: fill)
        .onChange(of: remind) { _, v in
            if v > 0 { Notifier.shared.requestIfNeeded { _ in refreshStatus() } }
        }
    }

    private var remindNote: String {
        switch notifyStatus {
        case .denied: return "Сповіщення вимкнено. Увімкни їх у Параметрах → Мій МЯУдень → Сповіщення, щоб нагадування приходили."
        default: return "Нагадування прийде вчасно, навіть якщо застосунок закритий."
        }
    }

    private func field<C: View>(_ label: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.nunito(14, .extraBold, relativeTo: .subheadline))
                .foregroundStyle(Theme.inkSoft)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    private func inputBackground(focused: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(focused ? Theme.accent : Theme.chip, lineWidth: 2))
    }

    private func fill() {
        refreshStatus()
        switch target {
        case .new(let d):
            day = DayKey.dateOrToday(d)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { textFocused = true }
        case .edit(let p):
            text = p.text
            day = DayKey.dateOrToday(p.date)
            if let start = p.startDate { hasTime = true; time = start }
            remind = p.remind
        }
    }

    private func refreshStatus() { Notifier.shared.authorizationStatus { notifyStatus = $0 } }

    private func save() {
        let clean = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !clean.isEmpty else { showError = true; textFocused = true; return }
        let dateKey = DayKey.key(day)
        var timeStr = ""
        if hasTime {
            let c = DayKey.calendar.dateComponents([.hour, .minute], from: time)
            timeStr = String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if let p = editing { store.update(p.id, text: clean, date: dateKey, time: timeStr, remind: remind) }
            else { store.add(text: clean, date: dateKey, time: timeStr, remind: remind) }
        }
        Haptics.success()
        dismiss()
    }
}
