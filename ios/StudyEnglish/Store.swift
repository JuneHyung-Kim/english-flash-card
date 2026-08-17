import Foundation
import SwiftUI

/// 학습 모드. 안드로이드의 EXTRA_MODE/EXTRA_SECTION에 대응.
enum StudyMode: Hashable {
    case all
    case section(Int)
    case user
    case bookmarked
    case collection  // 별도 섹션: "회화 표현"
}

/// 네비게이션 목적지.
enum Destination: Hashable {
    case study(StudyMode)
    case search
    case addCard
    case quiz
}

/// 앱 전역 상태 + 영속성. 안드로이드의 SharedPreferences("flashcard_prefs") + UserCardManager 역할.
final class Store: ObservableObject {
    static let sectionSize = 97  // 안드로이드 SECTION_SIZE
    static let collectionName = "회화 표현"  // 별도 섹션 이름

    @Published var userCards: [Flashcard] = []
    @Published var bookmarked: Set<String> = []
    @Published var excluded: Set<String> = []
    @Published var excludedTags: Set<String> = []
    /// 퀴즈로 시험볼 카드. 북마크(다시 보기)와 역할이 다르다.
    @Published var quizBank: Set<String> = []

    let baseCards: [Flashcard]
    let collectionCards: [Flashcard]  // 메인 덱과 분리된 별도 섹션 카드
    let allTags: [String]

    private let d = UserDefaults.standard
    private enum K {
        static let userCards = "user_cards"
        static let bookmarked = "bookmarked"
        static let excluded = "excluded"
        static let excludedTags = "excluded_tags"
        static let quizBank = "quiz_bank"
        static let quizSeeded = "quiz_seeded"
    }

    init() {
        baseCards = Store.loadBundledCards("flashcards")
        collectionCards = Store.loadBundledCards("conversation")
        allTags = Array(Set((baseCards + collectionCards).compactMap { $0.tag })).sorted()
        bookmarked = Set(d.stringArray(forKey: K.bookmarked) ?? [])
        excluded = Set(d.stringArray(forKey: K.excluded) ?? [])
        excludedTags = Set(d.stringArray(forKey: K.excludedTags) ?? [])
        userCards = Store.decodeCards(d.data(forKey: K.userCards))
        quizBank = Set(d.stringArray(forKey: K.quizBank) ?? [])
        seedQuizBankIfNeeded()
    }

    // MARK: - 카드 수 / 섹션

    var totalCount: Int { baseCards.count + userCards.count + collectionCards.count }

    var totalSections: Int {
        max(1, Int(ceil(Double(baseCards.count) / Double(Store.sectionSize))))
    }

    /// 메뉴의 섹션 라벨 ("섹션 1  (97장)"). 안드로이드 showSectionPicker와 동일한 계산.
    func sectionLabels() -> [String] {
        let k = totalSections
        let floor = baseCards.count / k
        let remainder = baseCards.count % k
        return (0..<k).map { s in
            let baseInSection = s < remainder ? floor + 1 : floor
            let userInSection = s == k - 1 ? userCards.count : 0
            return "섹션 \(s + 1)  (\(baseInSection + userInSection)장)"
        }
    }

    // MARK: - 토글 / 변경

    func toggleBookmark(_ key: String) {
        if bookmarked.contains(key) { bookmarked.remove(key) } else { bookmarked.insert(key) }
        d.set(Array(bookmarked), forKey: K.bookmarked)
    }

    func toggleExclude(_ key: String) {
        if excluded.contains(key) { excluded.remove(key) } else { excluded.insert(key) }
        d.set(Array(excluded), forKey: K.excluded)
    }

    func setExcludedTags(_ tags: Set<String>) {
        excludedTags = tags
        d.set(Array(tags), forKey: K.excludedTags)
    }

    func restoreAllExcluded() {
        excluded.removeAll()
        d.removeObject(forKey: K.excluded)
    }

    // MARK: - 퀴즈 뱅크

    /// 뱅크에 담긴 카드. ko가 중복인 카드가 몇 장 있어 키 기준으로 한 장만 남긴다.
    var quizCards: [Flashcard] {
        var seen = Set<String>()
        return (baseCards + collectionCards + userCards).filter {
            quizBank.contains($0.ko) && seen.insert($0.ko).inserted
        }
    }

    func toggleQuizBank(_ key: String) {
        if quizBank.contains(key) { quizBank.remove(key) } else { quizBank.insert(key) }
        saveQuizBank()
    }

    func removeFromQuizBank(_ keys: [String]) {
        quizBank.subtract(keys)
        saveQuizBank()
    }

    private func saveQuizBank() {
        d.set(Array(quizBank), forKey: K.quizBank)
    }

    /// 첫 실행 때만 시드 카드를 넣는다. 사용자가 지운 카드가 재실행 때 되살아나면 안 되므로 플래그로 1회 제한.
    private func seedQuizBankIfNeeded() {
        guard !d.bool(forKey: K.quizSeeded) else { return }
        d.set(true, forKey: K.quizSeeded)
        let available = Set(baseCards.map { $0.ko })
        let seeds = Store.seedKeys.filter { available.contains($0) }
        guard !seeds.isEmpty else { return }
        quizBank.formUnion(seeds)
        saveQuizBank()
    }

    /// 시드 10장: 3~5단어의 자주 쓰는 표현. 첫 타이핑 경험이 부담스럽지 않도록 짧은 것으로 골랐다.
    private static let seedKeys = [
        "무슨 생각하고 있어?",
        "요즘 뭐 하고 지내?",
        "무슨 일이야?",
        "무슨 뜻이야?",
        "잠깐 얘기할 시간 있어?",
        "지금 바빠?",
        "그 정도면 괜찮지?",
        "내가 한 말 취소할게",
        "이제 가볼게",
        "그건 말이 되네",
    ]

    func addUserCard(ko: String, en: String) {
        userCards.append(Flashcard(ko: ko, en: en))
        saveUserCards()
    }

    func deleteUserCard(at index: Int) {
        guard userCards.indices.contains(index) else { return }
        userCards.remove(at: index)
        saveUserCards()
    }

    private func saveUserCards() {
        let dtos = userCards.map { $0.dto }
        d.set(try? JSONEncoder().encode(dtos), forKey: K.userCards)
    }

    // MARK: - 진행 상태 (모드/섹션별)

    func progressIndexKey(for mode: StudyMode) -> String {
        switch mode {
        case .section(let n): return "progress_index_section_\(n)"
        case .user: return "progress_index_user"
        case .bookmarked: return "progress_index_bookmarked"
        case .collection: return "progress_index_collection"
        case .all: return "progress_index_default"
        }
    }
    func progressOrderKey(for mode: StudyMode) -> String {
        switch mode {
        case .section(let n): return "progress_order_section_\(n)"
        case .user: return "progress_order_user"
        case .bookmarked: return "progress_order_bookmarked"
        case .collection: return "progress_order_collection"
        case .all: return "progress_order_default"
        }
    }

    func saveProgress(mode: StudyMode, order: [String], index: Int) {
        d.set(order, forKey: progressOrderKey(for: mode))
        d.set(index, forKey: progressIndexKey(for: mode))
    }
    func savedOrder(for mode: StudyMode) -> [String]? {
        d.stringArray(forKey: progressOrderKey(for: mode))
    }
    func savedIndex(for mode: StudyMode) -> Int {
        d.object(forKey: progressIndexKey(for: mode)) == nil ? -1 : d.integer(forKey: progressIndexKey(for: mode))
    }

    // MARK: - 로딩

    private static func loadBundledCards(_ resource: String) -> [Flashcard] {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([CardDTO].self, from: data) else {
            return []
        }
        return dtos.map { Flashcard(dto: $0) }
    }

    private static func decodeCards(_ data: Data?) -> [Flashcard] {
        guard let data, let dtos = try? JSONDecoder().decode([CardDTO].self, from: data) else { return [] }
        return dtos.map { Flashcard(dto: $0) }
    }
}
