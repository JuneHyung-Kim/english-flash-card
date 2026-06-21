import SwiftUI

/// 카드 추가 화면. 안드로이드 AddCardActivity에 대응.
struct AddCardView: View {
    @EnvironmentObject var store: Store
    @State private var ko = ""
    @State private var en = ""
    @State private var showEmptyAlert = false

    var body: some View {
        Form {
            Section("새 카드") {
                TextField("한국어", text: $ko)
                TextField("영어", text: $en)
                Button("저장") { save() }
            }

            Section(store.userCards.isEmpty ? "추가한 카드가 없습니다." : "추가한 카드 (\(store.userCards.count)장)") {
                ForEach(Array(store.userCards.enumerated()), id: \.element.id) { _, card in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.ko)
                        Text(card.en).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    offsets.forEach { store.deleteUserCard(at: $0) }
                }
            }
        }
        .navigationTitle("카드 추가")
        .navigationBarTitleDisplayMode(.inline)
        .alert("한국어와 영어를 모두 입력해주세요.", isPresented: $showEmptyAlert) {
            Button("확인", role: .cancel) {}
        }
    }

    private func save() {
        let k = ko.trimmingCharacters(in: .whitespaces)
        let e = en.trimmingCharacters(in: .whitespaces)
        guard !k.isEmpty, !e.isEmpty else { showEmptyAlert = true; return }
        store.addUserCard(ko: k, en: e)
        ko = ""; en = ""
    }
}
