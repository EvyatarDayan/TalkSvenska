//
//  ManualSentenceRichText.swift
//  TalkSvenska
//

import SwiftUI
import UIKit

extension NSAttributedString.Key {
    /// In-memory tag for manual “B” emphasis (bold + red). Serialized via JSON ranges, not RTF custom keys.
    static let manualEmphasis = NSAttributedString.Key("TalkSvenska.manualEmphasis")
}

private struct ManualRichPayload: Codable {
    var v: Int = 1
    var text: String
    var marks: [Mark]
    struct Mark: Codable {
        var location: Int
        var length: Int
    }
}

enum ManualSentenceRichText {
    private static let jsonMagic = "TalkSvenskaRichV1\n"
    private static let titleUIFont = UIFont.preferredFont(forTextStyle: .title3)

    private static func markedFont(from base: UIFont = titleUIFont) -> UIFont {
        let desc = base.fontDescriptor.withSymbolicTraits(.traitBold) ?? base.fontDescriptor
        return UIFont(descriptor: desc, size: base.pointSize)
    }

    private static func defaultBodyAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: titleUIFont,
            .foregroundColor: UIColor.label
        ]
    }

    // MARK: - Storage detection

    static func isJSONRichStorage(_ string: String) -> Bool {
        string.hasPrefix(jsonMagic)
    }

    static func isHTMLStorage(_ string: String) -> Bool {
        let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.range(of: "<html", options: .caseInsensitive) != nil
    }

    /// Legacy / external rich (HTML from older builds, or JSON from current).
    static func isRichStorage(_ string: String) -> Bool {
        isJSONRichStorage(string) || isHTMLStorage(string)
    }

    // MARK: - Plain text

    static func plainText(from stored: String) -> String {
        if isJSONRichStorage(stored) {
            let jsonPart = String(stored.dropFirst(jsonMagic.count))
            guard let data = jsonPart.data(using: .utf8),
                  let payload = try? JSONDecoder().decode(ManualRichPayload.self, from: data) else {
                return stored
            }
            return payload.text
        }
        if isHTMLStorage(stored),
           let data = stored.data(using: .utf8),
           let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
           ) {
            return attributed.string
        }
        return stored
    }

    // MARK: - NSAttributedString <-> storage

    static func attributedString(from stored: String, font: UIFont = titleUIFont) -> NSAttributedString {
        if isJSONRichStorage(stored) {
            let jsonPart = String(stored.dropFirst(jsonMagic.count))
            guard let data = jsonPart.data(using: .utf8),
                  let payload = try? JSONDecoder().decode(ManualRichPayload.self, from: data) else {
                return NSAttributedString(string: plainText(from: stored), attributes: defaultBodyAttributes())
            }
            let m = NSMutableAttributedString(string: payload.text, attributes: [
                .font: font,
                .foregroundColor: UIColor.label
            ])
            for mk in payload.marks {
                let r = NSRange(location: mk.location, length: mk.length)
                guard r.location >= 0, r.length > 0, r.location + r.length <= m.length else { continue }
                applyEmphasis(in: m, range: r, baseFont: font)
            }
            return m
        }
        if isHTMLStorage(stored),
           let data = stored.data(using: .utf8),
           let m = try? NSMutableAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
           ) {
            migrateLegacyRedToEmphasis(m, baseFont: font)
            normalizeFonts(m, baseFont: font)
            return m
        }
        return NSAttributedString(string: stored, attributes: [
            .font: font,
            .foregroundColor: UIColor.label
        ])
    }

    static func swiftUIAttributedString(from stored: String) -> AttributedString {
        AttributedString(attributedString(from: stored))
    }

    static func storageString(from attributed: NSAttributedString) -> String {
        let m = NSMutableAttributedString(attributedString: attributed)
        migrateLegacyRedToEmphasis(m, baseFont: titleUIFont)
        let marks = collectMarkRanges(m)
        if marks.isEmpty {
            return m.string
        }
        let payload = ManualRichPayload(text: m.string, marks: marks)
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return m.string
        }
        return jsonMagic + json
    }

    // MARK: - Marking

    private static func collectMarkRanges(_ s: NSMutableAttributedString) -> [ManualRichPayload.Mark] {
        var out: [ManualRichPayload.Mark] = []
        let full = NSRange(location: 0, length: s.length)
        guard full.length > 0 else { return out }
        var idx = 0
        while idx < s.length {
            var eff = NSRange()
            let attrs = s.attributes(at: idx, longestEffectiveRange: &eff, in: full)
            if isMarkedAttributes(attrs) {
                out.append(.init(location: eff.location, length: eff.length))
            }
            idx = eff.location + eff.length
        }
        return out
    }

    private static func isMarkedAttributes(_ attrs: [NSAttributedString.Key: Any]) -> Bool {
        if attrs[.manualEmphasis] as? Bool == true { return true }
        if let c = attrs[.foregroundColor] as? UIColor, colorLooksRed(c),
           let f = attrs[.font] as? UIFont,
           f.fontDescriptor.symbolicTraits.contains(.traitBold) {
            return true
        }
        return false
    }

    private static func migrateLegacyRedToEmphasis(_ m: NSMutableAttributedString, baseFont: UIFont) {
        let full = NSRange(location: 0, length: m.length)
        guard full.length > 0 else { return }
        m.enumerateAttribute(.foregroundColor, in: full, options: []) { value, range, _ in
            guard let c = value as? UIColor, colorLooksRed(c) else { return }
            if m.attribute(.manualEmphasis, at: range.location, effectiveRange: nil) as? Bool == true { return }
            applyEmphasis(in: m, range: range, baseFont: baseFont)
        }
    }

    private static func normalizeFonts(_ m: NSMutableAttributedString, baseFont: UIFont) {
        let full = NSRange(location: 0, length: m.length)
        guard full.length > 0 else { return }
        var idx = 0
        while idx < m.length {
            var eff = NSRange()
            let attrs = m.attributes(at: idx, longestEffectiveRange: &eff, in: full)
            if attrs[.manualEmphasis] as? Bool == true {
                m.addAttributes([
                    .font: markedFont(from: baseFont),
                    .foregroundColor: UIColor.systemRed
                ], range: eff)
            } else {
                m.addAttributes([
                    .font: baseFont,
                    .foregroundColor: UIColor.label
                ], range: eff)
            }
            idx = eff.location + eff.length
        }
    }

    private static func colorLooksRed(_ color: UIColor) -> Bool {
        if color == .systemRed { return true }
        let cg = color.cgColor
        guard let space = cg.colorSpace, space.model == .rgb,
              let c = cg.components, c.count >= 3 else { return false }
        return c[0] > 0.75 && c[1] < 0.45 && c[2] < 0.45
    }

    private static func applyEmphasis(in m: NSMutableAttributedString, range: NSRange, baseFont: UIFont) {
        m.addAttributes([
            .manualEmphasis: true,
            .foregroundColor: UIColor.systemRed,
            .font: markedFont(from: baseFont)
        ], range: range)
    }

    private static func stripEmphasis(in m: NSMutableAttributedString, range: NSRange, baseFont: UIFont) {
        m.removeAttribute(.manualEmphasis, range: range)
        m.addAttributes([
            .font: baseFont,
            .foregroundColor: UIColor.label
        ], range: range)
    }

    /// Clears only marked subranges inside `range` so unmarked text in the same selection stays unchanged.
    private static func clearMarkingInSelection(in m: NSMutableAttributedString, range: NSRange, baseFont: UIFont) {
        var idx = range.location
        let end = range.location + range.length
        let searchRange = NSRange(location: range.location, length: range.length)
        while idx < end {
            var eff = NSRange()
            let attrs = m.attributes(at: idx, longestEffectiveRange: &eff, in: searchRange)
            let lo = max(eff.location, range.location)
            let hi = min(eff.location + eff.length, end)
            let slice = NSRange(location: lo, length: max(0, hi - lo))
            if slice.length > 0, isMarkedAttributes(attrs) {
                stripEmphasis(in: m, range: slice, baseFont: baseFont)
            }
            let next = eff.location + eff.length
            idx = next > idx ? next : idx + 1
        }
    }

    /// If the selection overlaps any marked (or legacy red) run, clear marking in the selection; otherwise mark the whole selection (bold + red).
    static func toggleManualEmphasis(in textView: UITextView) {
        let range = textView.selectedRange
        guard range.length > 0, range.location + range.length <= textView.attributedText.length else { return }

        let m = NSMutableAttributedString(attributedString: textView.attributedText)
        migrateLegacyRedToEmphasis(m, baseFont: titleUIFont)

        if rangeContainsMarkedOrLegacyRed(m, range: range) {
            clearMarkingInSelection(in: m, range: range, baseFont: titleUIFont)
        } else {
            applyEmphasis(in: m, range: range, baseFont: titleUIFont)
        }

        textView.attributedText = m
        textView.selectedRange = range
        textView.typingAttributes = defaultBodyAttributes()
    }

    private static func rangeContainsMarkedOrLegacyRed(_ s: NSAttributedString, range: NSRange) -> Bool {
        var found = false
        s.enumerateAttributes(in: range, options: []) { attrs, _, stop in
            if isMarkedAttributes(attrs) {
                found = true
                stop.pointee = true
            }
        }
        return found
    }
}

// MARK: - UITextView wrapper

struct ManualRichTextField: UIViewRepresentable {
    @Binding var textStorage: String
    @Binding var hasTextSelection: Bool
    var markRedNonce: Int
    var isEditable: Bool
    var onFocusChange: ((Bool) -> Void)?

    fileprivate static func selectionIsNonCollapsed(_ textView: UITextView) -> Bool {
        if textView.selectedRange.length > 0 { return true }
        guard let range = textView.selectedTextRange else { return false }
        return textView.offset(from: range.start, to: range.end) != 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = UIFont.preferredFont(forTextStyle: .title3)
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 4, bottom: 16, right: 4)
        tv.textContainer.lineFragmentPadding = 0
        tv.isScrollEnabled = true
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartDashesType = .no
        tv.smartQuotesType = .no
        tv.tintColor = .systemBlue
        tv.allowsEditingTextAttributes = true
        tv.typingAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .title3),
            .foregroundColor: UIColor.label
        ]
        context.coordinator.installEditMenuPreferringBelowSelection(on: tv)
        return tv
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.hasTextSelectionBinding = $hasTextSelection
        textView.isEditable = isEditable
        textView.allowsEditingTextAttributes = true

        if markRedNonce != context.coordinator.appliedMarkRedNonce {
            context.coordinator.appliedMarkRedNonce = markRedNonce
            ManualSentenceRichText.toggleManualEmphasis(in: textView)
            let next = ManualSentenceRichText.storageString(from: textView.attributedText)
            if next != textStorage {
                textStorage = next
            }
        } else {
            let serializedInView = ManualSentenceRichText.storageString(from: textView.attributedText)
            if serializedInView != textStorage {
                context.coordinator.isProgrammaticUpdate = true
                textView.attributedText = ManualSentenceRichText.attributedString(from: textStorage)
                context.coordinator.isProgrammaticUpdate = false
            }
        }

        let hasSel = Self.selectionIsNonCollapsed(textView)
        if context.coordinator.hasTextSelectionBinding?.wrappedValue != hasSel {
            context.coordinator.hasTextSelectionBinding?.wrappedValue = hasSel
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate, UIEditMenuInteractionDelegate {
        var parent: ManualRichTextField
        var hasTextSelectionBinding: Binding<Bool>?
        var isProgrammaticUpdate = false
        var appliedMarkRedNonce: Int = 0
        private weak var editMenuHostView: UITextView?
        private var customEditMenuInteraction: UIEditMenuInteraction?

        init(_ parent: ManualRichTextField) {
            self.parent = parent
        }

        /// Keep native `UITextView` edit-menu behavior (Cut/Copy/Paste/Select/Select All/Paste).
        /// We do not override interactions here to avoid suppressing the default menu presentation.
        func installEditMenuPreferringBelowSelection(on textView: UITextView) {
            editMenuHostView = textView
            customEditMenuInteraction = nil
        }

        func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
            nil
        }

        func editMenuInteraction(_ interaction: UIEditMenuInteraction, willPresentMenuFor configuration: UIEditMenuConfiguration, animator: any UIEditMenuInteractionAnimating) {}

        /// Use default anchoring from the system `UITextView`.
        func editMenuInteraction(_ interaction: UIEditMenuInteraction, targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
            .null
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isProgrammaticUpdate else { return }
            let next = ManualSentenceRichText.storageString(from: textView.attributedText)
            if next != parent.textStorage {
                parent.textStorage = next
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let hasSel = ManualRichTextField.selectionIsNonCollapsed(textView)
            if hasTextSelectionBinding?.wrappedValue != hasSel {
                hasTextSelectionBinding?.wrappedValue = hasSel
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            textView.typingAttributes = [
                .font: UIFont.preferredFont(forTextStyle: .title3),
                .foregroundColor: UIColor.label
            ]
            parent.onFocusChange?(true)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.onFocusChange?(false)
        }
    }
}
