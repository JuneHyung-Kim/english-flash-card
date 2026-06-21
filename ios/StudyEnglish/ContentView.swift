import SwiftUI

struct ContentView: View {
    @StateObject private var store = Store()
    @State private var path = NavigationPath()
    @State private var showSectionPicker = false
    @State private var showTagFilter = false
    @State private var showRestoreAlert = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 14) {
                    Text("영어 표현 암기")
                        .font(.largeTitle).bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("총 \(store.totalCount)장의 카드")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)

                    primaryButton("학습 시작") { showSectionPicker = true }

                    if !store.collectionCards.isEmpty {
                        menuButton("💬 \(Store.collectionName) (\(store.collectionCards.count)장)") {
                            path.append(Destination.study(.collection))
                        }
                    }
                    if !store.bookmarked.isEmpty {
                        menuButton("저장한 카드 학습 (\(store.bookmarked.count)장)") {
                            path.append(Destination.study(.bookmarked))
                        }
                    }
                    if !store.userCards.isEmpty {
                        menuButton("내가 추가한 카드 (\(store.userCards.count)장)") {
                            path.append(Destination.study(.user))
                        }
                    }
                    menuButton("🔍 검색") { path.append(Destination.search) }
                    menuButton("➕ 카드 추가") { path.append(Destination.addCard) }

                    let tagLabel = store.excludedTags.isEmpty
                        ? "🏷 태그 필터"
                        : "🏷 태그 필터 (\(store.excludedTags.count)개 제외 중)"
                    menuButton(tagLabel) { showTagFilter = true }

                    if !store.excluded.isEmpty {
                        menuButton("제외된 카드 \(store.excluded.count)장 복원") { showRestoreAlert = true }
                    }
                }
                .padding(20)
            }
            .navigationDestination(for: Destination.self) { dest in
                switch dest {
                case .study(let mode): StudyView(mode: mode, store: store)
                case .search: SearchView().environmentObject(store)
                case .addCard: AddCardView().environmentObject(store)
                }
            }
            .sheet(isPresented: $showSectionPicker) {
                SectionPickerView { section in
                    showSectionPicker = false
                    path.append(Destination.study(.section(section)))
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showTagFilter) {
                TagFilterView().environmentObject(store)
            }
            .alert("제외된 카드 복원", isPresented: $showRestoreAlert) {
                Button("취소", role: .cancel) {}
                Button("복원") { store.restoreAllExcluded() }
            } message: {
                Text("제외된 카드 \(store.excluded.count)장을 모두 복원하시겠습니까?")
            }
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3).bold()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func menuButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16).padding(.horizontal, 18)
                .background(Color(.secondarySystemBackground))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

/// 섹션 선택 시트.
struct SectionPickerView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            List(Array(store.sectionLabels().enumerated()), id: \.offset) { idx, label in
                Button(label) { onSelect(idx) }
            }
            .navigationTitle("섹션 선택")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
    }
}

/// 태그 필터 시트.
struct TagFilterView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []

    var body: some View {
        NavigationStack {
            List(store.allTags, id: \.self) { tag in
                Button {
                    if selected.contains(tag) { selected.remove(tag) } else { selected.insert(tag) }
                } label: {
                    HStack {
                        Text(tag).foregroundStyle(.primary)
                        Spacer()
                        if selected.contains(tag) { Image(systemName: "checkmark") }
                    }
                }
            }
            .navigationTitle("제외할 태그")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { store.setExcludedTags(selected); dismiss() }
                }
            }
            .onAppear { selected = store.excludedTags }
        }
    }
}

#Preview {
    ContentView()
}
