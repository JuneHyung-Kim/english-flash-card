import SwiftUI

/// 검색 화면. 안드로이드 SearchActivity에 대응. ko/en 부분일치(대소문자 무시).
struct SearchView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""

    private var allCards: [Flashcard] { store.baseCards + store.collectionCards + store.userCards }

    private var results: [Flashcard] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        return allCards.filter {
            $0.ko.lowercased().contains(lower) || $0.en.lowercased().contains(lower)
        }
    }

    var body: some View {
        List {
            if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                if results.isEmpty {
                    Text("\"\(query.trimmingCharacters(in: .whitespaces))\" 검색 결과가 없어요")
                        .foregroundStyle(.secondary)
                } else {
                    Section("\(results.count)개 결과") {
                        ForEach(results) { card in
                            ResultRow(card: card)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, prompt: "한국어 또는 영어로 검색")
        .navigationTitle("검색")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ResultRow: View {
    let card: Flashcard
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let tag = card.tag {
                    Text(tag)
                        .font(.caption2).bold()
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                Text(card.ko).font(.body)
                Text(card.en).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button { Speaker.shared.speak(card.en) } label: {
                Image(systemName: "speaker.wave.2.fill")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}
