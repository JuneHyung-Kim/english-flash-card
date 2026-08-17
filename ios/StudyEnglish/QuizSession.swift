import Foundation

/// 타이핑 답안 채점기.
/// 카드와 입력에 같은 정규화를 적용한 뒤 비교하므로, 규칙이 언어학적으로 정확할 필요는 없고 일관되기만 하면 된다.
enum QuizGrader {

    /// 대소문자·공백·구두점을 무시하고, 축약형은 풀어서 맞춘다. ("I'm gonna" ≡ "I am going to")
    /// surface 비교를 함께 두는 이유: 아포스트로피를 빼먹고 친 "whats"는 축약형을 풀 단서가 없어
    /// normalize만으로는 "what is"와 만나지 못한다. 표기 오차이지 표현 오류가 아니므로 정답으로 본다.
    static func matches(input: String, answer: String) -> Bool {
        let normalized = normalize(input)
        guard !normalized.isEmpty else { return false }
        return normalized == normalize(answer) || surface(input) == surface(answer)
    }

    /// 맞았지만 카드와 다른 표현을 썼는지. 축약형만 풀지 않은 채 비교해 대소문자/구두점 차이는 걸러낸다.
    static func differsInWording(_ input: String, _ answer: String) -> Bool {
        surface(input) != surface(answer)
    }

    /// 각 단어의 첫 글자만 남긴 힌트. "What's on your mind?" → "W___'_ o_ y___ m___?"
    static func mask(_ sentence: String) -> String {
        sentence.split(separator: " ").map { word -> String in
            var masked = ""
            var isFirst = true
            for ch in word {
                if ch.isLetter || ch.isNumber {
                    masked.append(isFirst ? ch : "_")
                    isFirst = false
                } else {
                    masked.append(ch)  // 아포스트로피와 구두점은 그대로 남겨 형태를 알려준다
                }
            }
            return masked
        }.joined(separator: " ")
    }

    static func normalize(_ s: String) -> String {
        var t = flatten(s)
        for (from, to) in expansions {
            t = t.replacingOccurrences(of: from, with: to)
        }
        return collapse(t)
    }

    /// 축약형을 풀지 않은 정규화. "What's on your mind?" → "whats on your mind"
    private static func surface(_ s: String) -> String {
        collapse(flatten(s))
    }

    private static func flatten(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{2019}", with: "'")  // iOS 키보드가 자동으로 넣는 곡선 따옴표
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .lowercased()
    }

    /// 아포스트로피는 지우고(what's → whats), 나머지 구두점은 공백으로 바꾼다.
    /// 공백으로 바꾸면 "what s"처럼 한 단어가 둘로 쪼개져 버린다.
    private static func collapse(_ s: String) -> String {
        s.replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .joined(separator: " ")
    }

    /// 순서가 중요하다. 불규칙형(can't)을 먼저 풀어야 일반 규칙(n't)이 "ca not"을 만들지 않는다.
    private static let expansions: [(String, String)] = [
        ("gonna", "going to"), ("wanna", "want to"), ("gotta", "got to"),
        ("cannot", "can not"), ("can't", "can not"), ("won't", "will not"), ("shan't", "shall not"),
        ("n't", " not"),
        ("'m", " am"), ("'ll", " will"), ("'ve", " have"),
        ("'re", " are"), ("'d", " would"), ("'s", " is"),
    ]
}

/// 퀴즈 한 판. 뱅크에서 최대 10문항을 뽑아 한국어만 보고 영어 문장 전체를 타이핑한다.
/// 정오답은 세션 안에서만 유효하고 저장하지 않는다.
final class QuizSession: ObservableObject {
    static let questionLimit = 10

    struct Answer: Identifiable {
        let id = UUID()
        let card: Flashcard
        let typed: String
        let correct: Bool
    }

    enum Feedback {
        case correct(differentWording: Bool)
        case wrong
        case gaveUp
    }

    @Published private(set) var questions: [Flashcard] = []
    @Published private(set) var index = 0
    @Published var input = ""
    @Published private(set) var feedback: Feedback?
    @Published private(set) var hintRevealed = false
    @Published private(set) var answers: [Answer] = []
    @Published private(set) var finished = false

    private let store: Store

    init(store: Store) {
        self.store = store
        draw()
    }

    var isEmpty: Bool { questions.isEmpty }
    var current: Flashcard? { questions.indices.contains(index) ? questions[index] : nil }
    var counter: String { questions.isEmpty ? "" : "\(index + 1) / \(questions.count)" }
    var isLastQuestion: Bool { index + 1 >= questions.count }
    var score: Int { answers.filter(\.correct).count }
    var wrongAnswers: [Answer] { answers.filter { !$0.correct } }
    var canSubmit: Bool { !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var hint: String { current.map { QuizGrader.mask($0.en) } ?? "" }

    // MARK: - 조작

    func revealHint() { hintRevealed = true }

    func submit() {
        guard let card = current, feedback == nil, canSubmit else { return }
        let correct = QuizGrader.matches(input: input, answer: card.en)
        feedback = correct
            ? .correct(differentWording: QuizGrader.differsInWording(input, card.en))
            : .wrong
        answers.append(Answer(card: card, typed: input, correct: correct))
    }

    func giveUp() {
        guard let card = current, feedback == nil else { return }
        feedback = .gaveUp
        answers.append(Answer(card: card, typed: input, correct: false))
    }

    func next() {
        guard feedback != nil else { return }
        if isLastQuestion {
            finished = true
            return
        }
        index += 1
        clearQuestionState()
    }

    /// 뱅크에서 다시 뽑아 새 판을 시작한다.
    func restart() {
        index = 0
        answers = []
        finished = false
        clearQuestionState()
        draw()
    }

    func speak() {
        if let card = current { Speaker.shared.speak(card.en) }
    }

    private func draw() {
        questions = Array(store.quizCards.shuffled().prefix(Self.questionLimit))
    }

    private func clearQuestionState() {
        input = ""
        feedback = nil
        hintRevealed = false
    }
}
