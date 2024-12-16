//
//  MailComposeView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/15/24.
//

import SwiftUI
import MessageUI

// Email View for sending mail
struct MailComposeView: UIViewControllerRepresentable {
    var recipients: [String]
    var subject: String
    var messageBody: String
    var attachmentData: Data
    var attachmentMimeType: String
    var attachmentFileName: String

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposeView

        init(_ parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setToRecipients(recipients)
        mail.setSubject(subject)
        mail.setMessageBody(messageBody, isHTML: false)
        mail.addAttachmentData(attachmentData, mimeType: attachmentMimeType, fileName: attachmentFileName)
        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}
