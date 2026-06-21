import Foundation

/// 카드 한 장. 안드로이드의 data class Flashcard(ko, en, tag, note)와 동일.
/// 북마크/제외/진행상태의 "키"는 안드로이드와 마찬가지로 ko(한국어) 문자열을 사용한다.
struct Flashcard: Identifiable, Hashable {
    let id = UUID()
    let ko: String
    let en: String
    var tag: String? = nil
    var note: String? = nil

    var key: String { ko }
}

/// JSON 디코딩/인코딩용 (id 제외).
struct CardDTO: Codable {
    let ko: String
    let en: String
    var tag: String? = nil
    var note: String? = nil
}

extension Flashcard {
    init(dto: CardDTO) {
        self.init(ko: dto.ko, en: dto.en, tag: dto.tag, note: dto.note)
    }
    var dto: CardDTO { CardDTO(ko: ko, en: en, tag: tag, note: note) }
}
