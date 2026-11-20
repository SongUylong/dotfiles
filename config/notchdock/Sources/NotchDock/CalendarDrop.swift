import EventKit
import SwiftUI

/// Calendar dropdown for the clock pill: month grid + the selected day's events (EventKit).
final class CalendarModel: ObservableObject {
    @Published var month = Calendar.current.dateInterval(of: .month, for: Date())!.start
    @Published var selected = Calendar.current.startOfDay(for: Date())
    @Published var events: [EKEvent] = []
    @Published var access: Bool? = nil
    private let store = EKEventStore()

    func load() {
        if access == true { fetch(); return }
        store.requestFullAccessToEvents { ok, _ in
            DispatchQueue.main.async { self.access = ok; if ok { self.fetch() } }
        }
    }

    func select(_ d: Date) { selected = d; fetch() }
    func shift(_ months: Int) { month = Calendar.current.date(byAdding: .month, value: months, to: month)! }
    func today() { month = Calendar.current.dateInterval(of: .month, for: Date())!.start; select(Calendar.current.startOfDay(for: Date())) }

    private func fetch() {
        let end = Calendar.current.date(byAdding: .day, value: 1, to: selected)!
        let pred = store.predicateForEvents(withStart: selected, end: end, calendars: nil)
        events = store.events(matching: pred).sorted { $0.startDate < $1.startDate }
    }

    /// 6 weeks starting on the Sunday/Monday before the 1st (follows the system first weekday).
    var days: [Date] {
        let cal = Calendar.current
        let wd = cal.component(.weekday, from: month)
        let lead = (wd - cal.firstWeekday + 7) % 7
        let start = cal.date(byAdding: .day, value: -lead, to: month)!
        return (0..<42).map { cal.date(byAdding: .day, value: $0, to: start)! }
    }
}

struct CalendarDropView: View {
    @ObservedObject var model: CalendarModel
    private let cal = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(model.month, format: .dateTime.month(.wide).year())
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(Mocha.text)
                Spacer()
                navButton("chevron.left") { model.shift(-1) }
                Text("Today").font(.system(size: 12, weight: .semibold)).foregroundStyle(Mocha.peach)
                    .padding(.horizontal, 8).frame(height: 24)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Mocha.surface0))
                    .onTapGesture { model.today() }
                navButton("chevron.right") { model.shift(1) }
            }
            let symbols = Array(cal.veryShortWeekdaySymbols[(cal.firstWeekday - 1)...] + cal.veryShortWeekdaySymbols[..<(cal.firstWeekday - 1)])
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(Array(symbols.enumerated()), id: \.offset) { _, s in
                    Text(s).font(.system(size: 11, weight: .semibold)).foregroundStyle(Mocha.overlay0)
                }
                ForEach(model.days, id: \.self) { d in dayCell(d) }
            }
            Rectangle().fill(Mocha.surface0).frame(height: 1)
            Text(model.selected, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 12, weight: .semibold)).foregroundStyle(Mocha.subtext)
            if model.access == false {
                Text("Allow Calendar access in System Settings → Privacy & Security → Calendars to see events.")
                    .font(.system(size: 11)).foregroundStyle(Mocha.peach)
            } else if model.events.isEmpty {
                Text("No events").font(.system(size: 12)).foregroundStyle(Mocha.overlay0)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(model.events, id: \.eventIdentifier) { e in eventRow(e) }
                    }
                }.frame(maxHeight: 150)
            }
        }
        .padding(14)
        .onAppear { model.load() }
    }

    private func dayCell(_ d: Date) -> some View {
        let inMonth = cal.isDate(d, equalTo: model.month, toGranularity: .month)
        let isToday = cal.isDateInToday(d)
        let isSel = cal.isDate(d, inSameDayAs: model.selected)
        return Text("\(cal.component(.day, from: d))")
            .font(.system(size: 12, weight: isToday ? .bold : .medium))
            .foregroundStyle(isToday ? Mocha.base : inMonth ? Mocha.text : Mocha.overlay0)
            .frame(width: 30, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isToday ? Mocha.peach : isSel ? Mocha.surface1 : .clear)
            )
            .contentShape(Rectangle())
            .onTapGesture { model.select(d) }
    }

    private func eventRow(_ e: EKEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 2).fill(Color(nsColor: e.calendar.color)).frame(width: 3, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(e.title ?? "").font(.system(size: 12, weight: .semibold)).foregroundStyle(Mocha.text).lineLimit(1)
                Text(e.isAllDay ? "All day" : "\(e.startDate.formatted(date: .omitted, time: .shortened)) – \(e.endDate.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11)).foregroundStyle(Mocha.subtext)
            }
        }
    }

    private func navButton(_ sym: String, _ f: @escaping () -> Void) -> some View {
        Image(systemName: sym).font(.system(size: 11, weight: .bold)).foregroundStyle(Mocha.text)
            .frame(width: 24, height: 24)
            .background(RoundedRectangle(cornerRadius: 7).fill(Mocha.surface0))
            .contentShape(Rectangle()).onTapGesture(perform: f)
    }
}
