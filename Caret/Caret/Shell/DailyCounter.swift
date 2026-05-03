import Combine
import Foundation

/// Counts accepted corrections per calendar day. Persists the running
/// total + the date in `UserDefaults` so it survives relaunches and
/// resets at midnight (whatever timezone the user is in).
///
/// Read by the menu bar; written by `SuggestionPanelController` when
/// a Tab-accept succeeds.
@MainActor
final class DailyCounter: ObservableObject {
    @Published private(set) var count: Int

    private var currentDay: String
    private let defaults: UserDefaults
    private let calendar: Calendar

    private static let countDefaultsKey = "caret.dailyCount"
    private static let dayDefaultsKey = "caret.dailyCountDay"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current, now: Date = Date()) {
        self.defaults = defaults
        self.calendar = calendar
        let today = Self.dayKey(for: now, calendar: calendar)
        let storedDay = defaults.string(forKey: Self.dayDefaultsKey)
        if storedDay == today {
            self.count = defaults.integer(forKey: Self.countDefaultsKey)
        } else {
            self.count = 0
        }
        self.currentDay = today
    }

    func increment(now: Date = Date()) {
        let today = Self.dayKey(for: now, calendar: calendar)
        if today != currentDay {
            count = 0
            currentDay = today
        }
        count += 1
        defaults.set(count, forKey: Self.countDefaultsKey)
        defaults.set(today, forKey: Self.dayDefaultsKey)
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0
        )
    }
}
