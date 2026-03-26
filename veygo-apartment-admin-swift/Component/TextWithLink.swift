//
//  LegalText.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import SwiftUI
import UIKit

struct TextWithLink: UIViewRepresentable {
    var fullText: String
    var highlightedTexts: [(String, () -> Void)]

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let targetWidth = proposal.width ?? uiView.bounds.width
        guard targetWidth > 0 else { return nil }

        let fittingSize = uiView.sizeThatFits(CGSize(width: targetWidth, height: .greatestFiniteMagnitude))
        return CGSize(width: targetWidth, height: fittingSize.height)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.isOpaque = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.attributedText = makeAttributedString()
        textView.linkTextAttributes = [:]
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = makeAttributedString()
        uiView.invalidateIntrinsicContentSize()
        uiView.setNeedsLayout()
        context.coordinator.highlightedTexts = highlightedTexts
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(highlightedTexts: highlightedTexts)
    }

    private func makeAttributedString() -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .footnote),
                .foregroundColor: UIColor(named: "FootNote") ?? UIColor.secondaryLabel
            ]
        )

        for (highlightedText, _) in highlightedTexts {
            let range = (fullText as NSString).range(of: highlightedText)
            guard range.location != NSNotFound else { continue }

            let encodedText = highlightedText.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? highlightedText

            attributed.addAttributes([
                .foregroundColor: UIColor(named: "TextLink") ?? UIColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .link: URL(string: "action://\(encodedText)") ?? URL(string: "about:blank")!
            ], range: range)
        }

        return attributed
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var highlightedTexts: [(String, () -> Void)]

        init(highlightedTexts: [(String, () -> Void)]) {
            self.highlightedTexts = highlightedTexts
        }

        private func handleTap(on url: URL) -> Bool {
            let tappedText = url.host(percentEncoded: false)
                ?? url.host
                ?? url.absoluteString.replacingOccurrences(of: "action://", with: "")

            for (text, action) in highlightedTexts where text == tappedText {
                action()
                break
            }

            return false
        }

        func textView(
            _ textView: UITextView,
            shouldInteractWith url: URL,
            in characterRange: NSRange
        ) -> Bool {
            handleTap(on: url)
        }
    }
}
