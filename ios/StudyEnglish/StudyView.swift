import SwiftUI

/// 학습 화면. 안드로이드 FlashcardActivity 화면에 대응.
/// 탭하면 뒷면+노트 공개, 좌우 스와이프로 다음/이전, 별=북마크, 눈=제외, 스피커=TTS.
struct StudyView: View {
    @EnvironmentObject var store: Store
    @StateObject private var session: StudySession
    @Environment(\.dismiss) private var dismiss

    init(mode: StudyMode, store: Store) {
        _session = StateObject(wrappedValue: StudySession(mode: mode, store: store))
    }

    var body: some View {
        Group {
            if session.isEmpty {
                ContentUnavailableView("카드가 없습니다.", systemImage: "tray")
            } else {
                content
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { Text(session.counter).font(.subheadline).foregroundStyle(.secondary) }
            ToolbarItem(placement: .topBarTrailing) {
                Button { session.speak() } label: { Image(systemName: "speaker.wave.2.fill") }
            }
        }
        .onDisappear { session.saveProgress() }
        .overlay(alignment: .bottom) {
            if let toast = session.toast {
                Text(toast)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.black.opacity(0.8))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: session.toast)
    }

    private var content: some View {
        VStack(spacing: 16) {
            card
                .contentShape(Rectangle())
                .onTapGesture { session.reveal() }
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if abs(value.translation.width) > abs(value.translation.height),
                               abs(value.translation.width) > 60 {
                                if value.translation.width < 0 { session.next() } else { session.prev() }
                            }
                        }
                )

            controls
        }
        .padding(20)
    }

    private var card: some View {
        VStack(spacing: 14) {
            if let tag = session.current?.tag {
                Text(tag)
                    .font(.caption).bold()
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            Text(session.frontText)
                .font(.title).bold()
                .multilineTextAlignment(.center)

            if session.revealed {
                Divider().padding(.horizontal, 40)
                Text(session.backText)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let note = session.current?.note {
                    Text(note)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            } else {
                Text("탭하면 뜻이 보여요")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var controls: some View {
        HStack(spacing: 24) {
            Button { session.prev() } label: { Image(systemName: "chevron.left") }

            Button { session.toggleBookmark() } label: {
                Image(systemName: session.isBookmarked() ? "star.fill" : "star")
                    .foregroundStyle(session.isBookmarked() ? .yellow : .secondary)
            }
            Button { session.toggleExclude() } label: {
                Image(systemName: session.isExcluded() ? "eye.slash.fill" : "eye.slash")
                    .foregroundStyle(session.isExcluded() ? .red : .secondary)
            }
            Button { session.toggleQuizBank() } label: {
                Image(systemName: session.isInQuizBank() ? "square.and.pencil.circle.fill" : "square.and.pencil.circle")
                    .foregroundStyle(session.isInQuizBank() ? Color.accentColor : .secondary)
            }

            Button { session.next() } label: { Image(systemName: "chevron.right") }
        }
        .font(.title2)
    }
}
