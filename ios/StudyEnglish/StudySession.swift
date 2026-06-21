import Foundation

/// 한 번의 학습 세션. 안드로이드 FlashcardActivity의 카드 빌드/셔플/진행 저장 로직을 옮긴 것.
final class StudySession: ObservableObject {
    @Published var cards: [Flashcard] = []
    @Published var index = 0
    @Published var revealed = false
    @Published var toast: String? = nil

    let mode: StudyMode
    private let store: Store

    init(mode: StudyMode, store: Store) {
        self.mode = mode
        self.store = store
        build()
    }

    var isEmpty: Bool { cards.isEmpty }
    var current: Flashcard? { cards.indices.contains(index) ? cards[index] : nil }
    var counter: String { cards.isEmpty ? "" : "\(index + 1) / \(cards.count)" }

    /// 앞면/뒷면 결정: 짝수 인덱스는 ko가 앞, 홀수는 en이 앞 (안드로이드 showCard와 동일).
    var frontText: String {
        guard let c = current else { return "" }
        return index % 2 == 0 ? c.ko : c.en
    }
    var backText: String {
        guard let c = current else { return "" }
        return index % 2 == 0 ? c.en : c.ko
    }

    // MARK: - 빌드

    private func build() {
        cards = loadCards()
        guard !cards.isEmpty else { return }

        // 저장된 진행 상태 복원 시도
        if let order = store.savedOrder(for: mode), store.savedIndex(for: mode) >= 0 {
            let byKey = Dictionary(cards.map { ($0.ko, $0) }, uniquingKeysWith: { a, _ in a })
            let restored = order.compactMap { byKey[$0] }
            if restored.count == cards.count {
                cards = restored
                index = min(max(0, store.savedIndex(for: mode)), cards.count - 1)
                return
            }
        }
        cards.shuffle()
    }

    /// 안드로이드 loadCards(mode)와 동일한 분배 규칙.
    private func loadCards() -> [Flashcard] {
        let base = store.baseCards
        let user = store.userCards
        func keep(_ c: Flashcard) -> Bool {
            !store.excluded.contains(c.ko) && !(c.tag.map { store.excludedTags.contains($0) } ?? false)
        }

        switch mode {
        case .section(let sectionNumber):
            let sorted = base.sorted { ($0.tag ?? "") < ($1.tag ?? "") }
            let k = max(1, Int(ceil(Double(sorted.count) / Double(Store.sectionSize))))
            let lastSection = k - 1
            let sectionBase = sorted.enumerated().filter { $0.offset % k == sectionNumber }.map { $0.element }
            let pool = sectionNumber == lastSection ? sectionBase + user : sectionBase
            return pool.filter(keep)
        case .user:
            return user.filter(keep)
        case .bookmarked:
            return (base + store.collectionCards + user).filter { store.bookmarked.contains($0.ko) && keep($0) }
        case .collection:
            return store.collectionCards.filter(keep)
        case .all:
            return (base + user).filter(keep)
        }
    }

    // MARK: - 조작

    func reveal() { revealed = true }

    func next() {
        index += 1
        if index >= cards.count {
            cards.shuffle()
            index = 0
            flash("전체 완료! 카드를 다시 섞었습니다.")
        }
        revealed = false
        saveProgress()
    }

    func prev() {
        index = (index - 1 + cards.count) % cards.count
        revealed = false
        saveProgress()
    }

    func speak() {
        if let c = current { Speaker.shared.speak(c.en) }
    }

    func toggleBookmark() {
        if let c = current { store.toggleBookmark(c.ko); objectWillChange.send() }
    }
    func toggleExclude() {
        if let c = current { store.toggleExclude(c.ko); objectWillChange.send() }
    }
    func isBookmarked() -> Bool { current.map { store.bookmarked.contains($0.ko) } ?? false }
    func isExcluded() -> Bool { current.map { store.excluded.contains($0.ko) } ?? false }

    func saveProgress() {
        guard !cards.isEmpty else { return }
        store.saveProgress(mode: mode, order: cards.map { $0.ko }, index: index)
    }

    private func flash(_ message: String) {
        toast = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if self.toast == message { self.toast = nil }
        }
    }
}
