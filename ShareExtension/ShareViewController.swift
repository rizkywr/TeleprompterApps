//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Rizky Wahyu Ramadhan on 15/11/26.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let snippetLabel = UILabel()
    private let statusIcon = UIImageView()
    private let actionButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private var extractedTitle: String = ""
    private var extractedContent: String = ""
    private var isProcessed: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractAllContent()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor.systemBackground
        cardView.layer.cornerRadius = 24
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.25
        cardView.layer.shadowOffset = CGSize(width: 0, height: 10)
        cardView.layer.shadowRadius = 20
        view.addSubview(cardView)

        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.image = UIImage(systemName: "doc.text.fill")
        statusIcon.tintColor = UIColor(red: 0.16, green: 0.50, blue: 0.98, alpha: 1.0)
        statusIcon.contentMode = .scaleAspectFit
        cardView.addSubview(statusIcon)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Reading Note..."
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        cardView.addSubview(titleLabel)

        snippetLabel.translatesAutoresizingMaskIntoConstraints = false
        snippetLabel.text = "Preparing your script for PromptCam"
        snippetLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        snippetLabel.textAlignment = .center
        snippetLabel.textColor = UIColor.secondaryLabel
        snippetLabel.numberOfLines = 3
        cardView.addSubview(snippetLabel)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor(red: 0.16, green: 0.50, blue: 0.98, alpha: 1.0)
        activityIndicator.startAnimating()
        cardView.addSubview(activityIndicator)

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle("Open PromptCam", for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        actionButton.backgroundColor = UIColor(red: 0.16, green: 0.50, blue: 0.98, alpha: 1.0)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.cornerRadius = 14
        actionButton.addTarget(self, action: #selector(handleOpenPromptCamTapped), for: .touchUpInside)
        actionButton.isHidden = true
        cardView.addSubview(actionButton)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Done", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cancelButton.setTitleColor(UIColor.secondaryLabel, for: .normal)
        cancelButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        cardView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(equalToConstant: 320),

            statusIcon.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            statusIcon.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 52),
            statusIcon.heightAnchor.constraint(equalToConstant: 52),

            titleLabel.topAnchor.constraint(equalTo: statusIcon.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            snippetLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            snippetLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            snippetLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            activityIndicator.topAnchor.constraint(equalTo: snippetLabel.bottomAnchor, constant: 16),
            activityIndicator.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            actionButton.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            actionButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 48),

            cancelButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            cancelButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            cancelButton.heightAnchor.constraint(equalToConstant: 36),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
    }

    private func extractAllContent() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem], !items.isEmpty else {
            finishWithResult(title: "Shared Note", content: "")
            return
        }

        // 1. Direct text in extension item
        for item in items {
            if let text = item.attributedContentText?.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let title = item.attributedTitle?.string ?? deriveTitle(from: text)
                finishWithResult(title: title, content: text)
                return
            }
        }

        // 2. Attachments
        var allProviders: [NSItemProvider] = []
        for item in items {
            if let attachments = item.attachments {
                allProviders.append(contentsOf: attachments)
            }
        }

        guard !allProviders.isEmpty else {
            finishWithResult(title: "Shared Note", content: "")
            return
        }

        processProvider(providers: allProviders, providerIndex: 0)
    }

    private func processProvider(providers: [NSItemProvider], providerIndex: Int) {
        guard providerIndex < providers.count else {
            finishWithResult(title: "Shared Note", content: "")
            return
        }

        let provider = providers[providerIndex]
        let types = provider.registeredTypeIdentifiers

        // Priority types for text extraction
        let priorityOrder = [
            UTType.plainText.identifier,
            UTType.utf8PlainText.identifier,
            UTType.text.identifier,
            UTType.rtf.identifier,
            UTType.html.identifier,
            UTType.url.identifier,
            UTType.item.identifier
        ]

        var candidateTypes: [String] = []
        for p in priorityOrder {
            if types.contains(where: { $0 == p || provider.hasItemConformingToTypeIdentifier(p) }) {
                candidateTypes.append(p)
            }
        }
        for t in types {
            if !candidateTypes.contains(t) {
                candidateTypes.append(t)
            }
        }

        tryLoadTypes(provider: provider, types: candidateTypes, typeIndex: 0) { [weak self] extracted in
            if let extracted = extracted, !extracted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let title = self?.deriveTitle(from: extracted) ?? "Shared Note"
                self?.finishWithResult(title: title, content: extracted)
            } else {
                self?.processProvider(providers: providers, providerIndex: providerIndex + 1)
            }
        }
    }

    private func tryLoadTypes(provider: NSItemProvider, types: [String], typeIndex: Int, completion: @escaping (String?) -> Void) {
        guard typeIndex < types.count else {
            completion(nil)
            return
        }

        let typeIdentifier = types[typeIndex]
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (data, error) in
            if let text = self?.parseItemData(data), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DispatchQueue.main.async { completion(text) }
            } else {
                DispatchQueue.main.async {
                    self?.tryLoadTypes(provider: provider, types: types, typeIndex: typeIndex + 1, completion: completion)
                }
            }
        }
    }

    private func parseItemData(_ data: Any?) -> String? {
        if let string = data as? String {
            return string
        }
        if let attr = data as? NSAttributedString {
            return attr.string
        }
        if let url = data as? URL {
            let isSecurityScoped = url.startAccessingSecurityScopedResource()
            defer {
                if isSecurityScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            if let plain = try? String(contentsOf: url, encoding: .utf8) {
                return plain
            }
            if let attributed = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
                return attributed.string
            }
            if let latin = try? String(contentsOf: url, encoding: .isoLatin1) {
                return latin
            }
        }
        if let rawData = data as? Data {
            if let plain = String(data: rawData, encoding: .utf8) {
                return plain
            }
            if let attributed = try? NSAttributedString(data: rawData, options: [:], documentAttributes: nil) {
                return attributed.string
            }
        }
        return nil
    }

    private func deriveTitle(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.first ?? "Shared Note"
    }

    private func finishWithResult(title: String, content: String) {
        activityIndicator.stopAnimating()
        extractedTitle = title
        extractedContent = content

        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Save to universal pasteboard with signature
            saveToPasteboard(title: title, content: content)

            statusIcon.image = UIImage(systemName: "checkmark.circle.fill")
            statusIcon.tintColor = UIColor.systemGreen
            titleLabel.text = "Script Ready!"
            snippetLabel.text = "\"\(title)\"\nSaved to PromptCam"

            actionButton.isHidden = false

            // Auto-open host app after brief visual confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.performOpenPromptCam()
            }
        } else {
            statusIcon.image = UIImage(systemName: "exclamationmark.circle.fill")
            statusIcon.tintColor = UIColor.systemOrange
            titleLabel.text = "No Text Found"
            snippetLabel.text = "Make sure your note contains text to create a script."
            cancelButton.setTitle("Close", for: .normal)
        }
    }

    private func saveToPasteboard(title: String, content: String) {
        // Universal tagged format
        let payload = "PROMPTCAM_IMPORT_MAGIC\n" + title + "\n---PROMPTCAM_SPLIT---\n" + content
        UIPasteboard.general.string = payload
        UIPasteboard.general.setValue(content, forPasteboardType: "com.promptcam.sharedScript")
        UIPasteboard.general.setValue(title, forPasteboardType: "com.promptcam.sharedScriptTitle")
    }

    @objc private func handleOpenPromptCamTapped() {
        performOpenPromptCam()
    }

    private func performOpenPromptCam() {
        guard !isProcessed else { return }
        isProcessed = true

        saveToPasteboard(title: extractedTitle, content: extractedContent)

        guard let targetURL = URL(string: "promptcam://new") else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        openHostApp(url: targetURL) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    private func openHostApp(url: URL, completion: @escaping () -> Void) {
        let selectorWithHandler = sel_registerName("openURL:completionHandler:")
        let selectorSimple = sel_registerName("openURL:")

        // 1. Try extensionContext
        if let ctx = self.extensionContext as AnyObject? {
            if ctx.responds(to: selectorWithHandler) {
                let handler: @convention(block) (Bool) -> Void = { _ in
                    DispatchQueue.main.async { completion() }
                }
                ctx.perform(selectorWithHandler, with: url, with: handler)
                return
            } else if ctx.responds(to: selectorSimple) {
                ctx.perform(selectorSimple, with: url)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { completion() }
                return
            }
        }

        // 2. Try responder chain
        var responder: UIResponder? = self
        while let r = responder {
            if r.responds(to: selectorWithHandler) {
                let handler: @convention(block) (Bool) -> Void = { _ in
                    DispatchQueue.main.async { completion() }
                }
                r.perform(selectorWithHandler, with: url, with: handler)
                return
            } else if r.responds(to: selectorSimple) {
                r.perform(selectorSimple, with: url)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { completion() }
                return
            }
            responder = r.next
        }

        // 3. Fallback: UIApplication sharedApplication via reflection
        if let appClass = NSClassFromString("UIApplication") as? NSObject.Type {
            let sharedSel = sel_registerName("sharedApplication")
            if appClass.responds(to: sharedSel) {
                if let app = appClass.perform(sharedSel)?.takeUnretainedValue() as? NSObject {
                    if app.responds(to: selectorSimple) {
                        app.perform(selectorSimple, with: url)
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { completion() }
    }

    @objc private func handleDismiss() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
