import SwiftUI

/// 퀴즈 화면. 한국어만 보고 영어 문장 전체를 타이핑한다.
/// 힌트(각 단어 첫 글자)와 "모르겠어요"로 언제든 빠져나올 수 있고, 결과는 저장하지 않는다.
struct QuizView: View {
    @EnvironmentObject var store: Store
    @StateObject private var session: QuizSession
    @Environment(\.dismiss) private var dismiss
    @State private var showBank = false
    @FocusState private var inputFocused: Bool

    init(store: Store) {
        _session = StateObject(wrappedValue: QuizSession(store: store))
    }

    var body: some View {
        Group {
            if session.isEmpty {
                ContentUnavailableView(
                    "퀴즈 뱅크가 비어 있습니다",
                    systemImage: "square.and.pencil",
                    description: Text("학습 화면에서 ✎ 버튼을 눌러 시험볼 카드를 담아보세요.")
                )
            } else if session.finished {
                resultView
            } else {
                questionView
            }
        }
        .navigationTitle("퀴즈")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !session.isEmpty && !session.finished {
                ToolbarItem(placement: .principal) {
                    Text(session.counter).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showBank = true } label: { Image(systemName: "list.bullet") }
            }
        }
        .sheet(isPresented: $showBank) {
            QuizBankView().environmentObject(store)
        }
    }

    // MARK: - 문제

    private var questionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let tag = session.current?.tag {
                    Text(tag)
                        .font(.caption).bold()
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(session.current?.ko ?? "")
                    .font(.title).bold()
                    .fixedSize(horizontal: false, vertical: true)

                if session.hintRevealed {
                    Text(session.hint)
                        .font(.title3).monospaced()
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                TextField("영어로 입력", text: $session.input)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($inputFocused)
                    .disabled(session.feedback != nil)
                    .onSubmit { session.submit() }

                if let feedback = session.feedback {
                    feedbackBlock(feedback)
                } else {
                    actionButtons
                }
            }
            .padding(20)
        }
        .onAppear { inputFocused = true }
        // 다음 문항으로 넘어간 뒤 포커스를 되돌린다.
        // "다음" 버튼에서 바로 지정하면 TextField의 disabled가 풀리기 전이라 포커스가 먹지 않는다.
        .onChange(of: session.index) { inputFocused = true }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { session.submit() } label: {
                Text("확인")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(session.canSubmit ? Color.accentColor : Color.gray.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!session.canSubmit)

            HStack(spacing: 12) {
                Button("힌트") { session.revealHint() }
                    .disabled(session.hintRevealed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("모르겠어요") { session.giveUp() }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .font(.subheadline)
        }
    }

    @ViewBuilder
    private func feedbackBlock(_ feedback: QuizSession.Feedback) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            switch feedback {
            case .correct:
                Label("정답입니다", systemImage: "checkmark.circle.fill")
                    .font(.headline).foregroundStyle(.green)
            case .wrong:
                Label("아쉬워요", systemImage: "xmark.circle.fill")
                    .font(.headline).foregroundStyle(.red)
            case .gaveUp:
                Label("정답을 확인하세요", systemImage: "eye.fill")
                    .font(.headline).foregroundStyle(.orange)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(session.current?.en ?? "")
                    .font(.title3).bold()
                    .fixedSize(horizontal: false, vertical: true)
                Button { session.speak() } label: { Image(systemName: "speaker.wave.2.fill") }
            }

            if case .correct(let differentWording) = feedback, differentWording {
                Text("입력하신 표현도 맞지만, 카드는 위 표현을 씁니다.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            if let note = session.current?.note {
                Text(note)
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                session.next()
            } label: {
                Text(session.isLastQuestion ? "결과 보기" : "다음")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 결과

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("\(session.score) / \(session.questions.count)")
                        .font(.system(size: 52, weight: .bold))
                    Text(session.score == session.questions.count ? "전부 맞혔습니다!" : "수고하셨어요")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 24)

                if !session.wrongAnswers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("틀린 문항").font(.headline)
                        ForEach(session.wrongAnswers) { answer in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(answer.card.ko).font(.subheadline)
                                Text(answer.card.en).font(.headline)
                                if !answer.typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("입력: \(answer.typed)")
                                        .font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                Button {
                    session.restart()
                } label: {
                    Text("다시 풀기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("닫기") { dismiss() }
                    .padding(.vertical, 8)
            }
            .padding(20)
        }
    }
}

/// 퀴즈 뱅크 목록. 스와이프로 뺄 수 있다.
struct QuizBankView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.quizCards.isEmpty {
                    ContentUnavailableView(
                        "뱅크가 비어 있습니다",
                        systemImage: "tray",
                        description: Text("학습 화면에서 ✎ 버튼을 눌러 카드를 담아보세요.")
                    )
                } else {
                    List {
                        ForEach(store.quizCards) { card in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.ko)
                                Text(card.en).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { offsets in
                            let cards = store.quizCards
                            store.removeFromQuizBank(offsets.map { cards[$0].ko })
                        }
                    }
                }
            }
            .navigationTitle("퀴즈 뱅크 (\(store.quizBank.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
            }
        }
    }
}
