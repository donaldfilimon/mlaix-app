//
//  PrimarySectionTests.swift
//  MLAIXTests
//
//  Tests for PrimarySection navigation enum (title, subtitle, icon, identity).
//

import Foundation
import Testing
@testable import MLAIX

struct PrimarySectionTests {

    @Test func primarySectionHasFiveCases() {
        let all = PrimarySection.allCases
        #expect(all.count == 5)
    }

    @Test func primarySectionIdsAreRawValues() {
        for section in PrimarySection.allCases {
            #expect(section.id == section.rawValue)
        }
    }

    @Test(arguments: PrimarySection.allCases)
    func primarySectionTitlesAreNonEmpty(section: PrimarySection) {
        #expect(!section.title.isEmpty, "\(section) should have a non-empty title")
    }

    @Test(arguments: PrimarySection.allCases)
    func primarySectionSubtitlesAreNonEmpty(section: PrimarySection) {
        #expect(!section.subtitle.isEmpty, "\(section) should have a non-empty subtitle")
    }

    @Test(arguments: PrimarySection.allCases)
    func primarySectionSystemImagesAreNonEmpty(section: PrimarySection) {
        #expect(!section.systemImage.isEmpty, "\(section) should have a system image")
    }

    @Test func primarySectionConversationsValues() {
        #expect(PrimarySection.conversations.title == String(localized: "Conversations"))
        #expect(PrimarySection.conversations.systemImage == "bubble.left.and.text.bubble.right")
    }

    @Test func primarySectionToolsValues() {
        #expect(PrimarySection.tools.systemImage == "wrench.and.screwdriver")
    }

    @Test func primarySectionModelsValues() {
        #expect(PrimarySection.models.systemImage == "cpu")
    }

    @Test func primarySectionMemoryValues() {
        #expect(PrimarySection.memory.systemImage == "brain")
    }

    @Test func primarySectionSettingsValues() {
        #expect(PrimarySection.settings.systemImage == "gearshape")
    }

    @Test func primarySectionIdentifiable() {
        let ids = Set(PrimarySection.allCases.map(\.id))
        #expect(ids.count == PrimarySection.allCases.count)
    }
}
