import Foundation
import Testing
@testable import UniversalControlCore

@Suite struct RelayMessageTests {
    @Test func roundTripToggleMessage() throws {
        let original = RelayMessage.toggleInputSource(token: "123456")
        let encoded = try RelayCodec.encodeLine(original)
        let decoded = try RelayCodec.decode(encoded.dropLast())
        #expect(decoded == original)
    }

    @Test func roundTripInputSourceStateMessage() throws {
        let original = RelayMessage.setInputSource(.korean, token: "123456")
        let encoded = try RelayCodec.encodeLine(original)
        let decoded = try RelayCodec.decode(encoded.dropLast())

        #expect(decoded == original)
        #expect(decoded.protocolVersion == 2)
        #expect(decoded.inputSource == .korean)
    }

    @Test func handshakeRemainsDecodableByLegacyPeer() throws {
        struct LegacyMessage: Decodable {
            let kind: String
            let token: String
        }

        let encoded = try RelayCodec.encodeLine(.hello(token: "123456"))
        let decoded = try JSONDecoder().decode(LegacyMessage.self, from: encoded.dropLast())

        #expect(decoded.kind == "hello")
        #expect(decoded.token == "123456")
    }

    @Test func legacyPeerDoesNotReceiveDuplicateStateSynchronization() {
        #expect(!RelayProtocol.supportsExplicitInputSourceState(1))
        #expect(RelayProtocol.supportsExplicitInputSourceState(2))
    }

    @Test func framerHandlesSplitAndCombinedPackets() throws {
        let first = try RelayCodec.encodeLine(.hello(token: "111111"))
        let second = try RelayCodec.encodeLine(.toggleInputSource(token: "111111"))
        let joined = first + second
        let split = joined.count / 2
        var framer = LineFramer()

        let initial = try framer.append(joined.prefix(split))
        let remaining = try framer.append(joined.suffix(from: split))

        #expect(initial.count <= 1)
        #expect(initial.count + remaining.count == 2)
        #expect(try RelayCodec.decode((initial + remaining)[0]).kind == .hello)
        #expect(try RelayCodec.decode((initial + remaining)[1]).kind == .toggleInputSource)
    }

    @Test func framerRejectsOversizedFrame() {
        var framer = LineFramer(maximumFrameSize: 4)
        #expect(throws: LineFramer.FramingError.frameTooLarge) {
            try framer.append(Data(repeating: 0x41, count: 5))
        }
    }

    @Test func pairingCodeValidation() {
        #expect(PairingCode.isValid("012345"))
        #expect(!PairingCode.isValid("12345"))
        #expect(!PairingCode.isValid("12A456"))
        #expect(PairingCode.generate().count == 6)
    }

    @Test func inputSourceSelectionTogglesKoreanAndABC() {
        let sources = [
            InputSourceDescriptor(id: "com.apple.keylayout.ABC", name: "ABC"),
            InputSourceDescriptor(id: "com.apple.inputmethod.Korean.2SetKorean", name: "두벌식"),
        ]
        #expect(
            InputSourceSelection.targetID(currentID: "com.apple.inputmethod.Korean.2SetKorean", candidates: sources)
                == "com.apple.keylayout.ABC"
        )
        #expect(
            InputSourceSelection.targetID(currentID: "com.apple.keylayout.ABC", candidates: sources)
                == "com.apple.inputmethod.Korean.2SetKorean"
        )
    }

    @Test func inputSourceSelectionClassifiesAndSelectsExplicitState() {
        let sources = [
            InputSourceDescriptor(id: "com.apple.keylayout.ABC", name: "ABC"),
            InputSourceDescriptor(id: "com.apple.inputmethod.Korean.2SetKorean", name: "두벌식"),
        ]

        #expect(InputSourceSelection.state(id: sources[0].id, name: sources[0].name) == .abc)
        #expect(InputSourceSelection.state(id: sources[1].id, name: sources[1].name) == .korean)
        #expect(InputSourceSelection.state(id: "com.apple.CharacterPaletteIM", name: "이모티콘") == nil)
        #expect(
            InputSourceSelection.targetID(for: .abc, candidates: sources)
                == "com.apple.keylayout.ABC"
        )
        #expect(
            InputSourceSelection.targetID(for: .korean, candidates: sources)
                == "com.apple.inputmethod.Korean.2SetKorean"
        )
    }

    @Test func inputSourceSelectionTogglesThaiAndABC() {
        let sources = [
            InputSourceDescriptor(id: "com.apple.keylayout.ABC", name: "ABC"),
            InputSourceDescriptor(id: "com.apple.keylayout.Thai", name: "Thai"),
        ]
        #expect(
            InputSourceSelection.targetID(currentID: "com.apple.keylayout.Thai", candidates: sources)
                == "com.apple.keylayout.ABC"
        )
        #expect(
            InputSourceSelection.targetID(currentID: "com.apple.keylayout.ABC", candidates: sources)
                == "com.apple.keylayout.Thai"
        )
    }

    @Test func inputSourceSelectionClassifiesAndSelectsThaiState() {
        let sources = [
            InputSourceDescriptor(id: "com.apple.keylayout.ABC", name: "ABC"),
            InputSourceDescriptor(id: "com.apple.keylayout.Thai", name: "Thai"),
        ]

        #expect(InputSourceSelection.state(id: sources[0].id, name: sources[0].name) == .abc)
        #expect(InputSourceSelection.state(id: sources[1].id, name: sources[1].name) == .thai)
        #expect(
            InputSourceSelection.targetID(for: .thai, candidates: sources)
                == "com.apple.keylayout.Thai"
        )
    }

    @Test func roundTripThaiInputSourceStateMessage() throws {
        let original = RelayMessage.setInputSource(.thai, token: "123456")
        let encoded = try RelayCodec.encodeLine(original)
        let decoded = try RelayCodec.decode(encoded.dropLast())

        #expect(decoded == original)
        #expect(decoded.inputSource == .thai)
    }
}
