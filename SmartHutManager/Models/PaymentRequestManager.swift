import Foundation
import PassKit
import MessageUI
import UIKit

class PaymentRequestManager: NSObject, MFMailComposeViewControllerDelegate, PKPaymentAuthorizationViewControllerDelegate {
    
    private var onSuccess: (() -> Void)?
    private var onError: ((String) -> Void)?

    // Singleton instance
    static let shared = PaymentRequestManager()

    // MARK: - Request Payment
    func requestPayment(for customer: Customer, amount: Double, paymentMethod: PaymentMethod, from viewController: UIViewController, onSuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError

        switch paymentMethod {
        case .applePay:
            initiateApplePay(for: customer, amount: amount, from: viewController)
        case .paypal, .zelle:
            sendPaymentLink(for: customer, method: paymentMethod, amount: amount, from: viewController)
        case .cash:
            // Handle cash payment case
            showAlert(title: "Cash Payment",
                      message: "Please collect $\(String(format: "%.2f", amount)) in cash from the customer.",
                      on: viewController)
            onSuccess()
        }
    }

    // MARK: - Apple Pay Handling
    private func initiateApplePay(for customer: Customer, amount: Double, from viewController: UIViewController) {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "merchant.SmarthutATL.com"
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex]
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"
        
        // Customer name fallback
        let customerName = customer.name ?? "Customer"
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: customerName, amount: NSDecimalNumber(value: amount))
        ]

        guard let paymentAuthorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else {
            onError?("Unable to present Apple Pay interface.")
            return
        }

        paymentAuthorizationViewController.delegate = self
        viewController.present(paymentAuthorizationViewController, animated: true)
    }

    // MARK: - PayPal and Zelle Link Handling
    private func sendPaymentLink(for customer: Customer, method: PaymentMethod, amount: Double, from viewController: UIViewController) {
        let paymentService = (method == .paypal) ? "PayPal" : "Zelle"
        let customerName = customer.name ?? "Customer"
        let messageBody = """
        Hi \(customerName),
        
        You owe $\(String(format: "%.2f", amount)).
        
        Please use the following \(paymentService) link to pay:
        
        \(generatePaymentLink(for: method, amount: amount))
        
        Thank you!
        """

        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([customer.email ?? ""])
            mailComposer.setSubject("\(paymentService) Payment Request")
            mailComposer.setMessageBody(messageBody, isHTML: false)
            
            viewController.present(mailComposer, animated: true)
        } else {
            showAlert(
                title: "Mail Not Available",
                message: "Please configure a mail account to send payment requests.",
                on: viewController
            )
        }
    }

    // MARK: - Generate Payment Link
    func generatePaymentLink(for method: PaymentMethod, amount: Double) -> String {
        switch method {
        case .paypal:
            return "https://www.paypal.me/yourbusiness/\(String(format: "%.2f", amount))"
        case .zelle:
            return "https://zellepay.com/pay/smarthutatl@gmail.com"
        default:
            return ""
        }
    }

    // MARK: - PKPaymentAuthorizationViewControllerDelegate
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true) {
            self.onError?("Payment canceled or failed.")
        }
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        completion: @escaping (PKPaymentAuthorizationStatus) -> Void
    ) {
        // Simulate payment success
        let paymentSuccess = true // Replace with your payment validation logic

        if paymentSuccess {
            completion(.success)
            onSuccess?()
        } else {
            completion(.failure)
            onError?("Payment authorization failed.")
        }
    }

    // MARK: - Mail Compose Delegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: - Utility Function
    private func showAlert(title: String, message: String, on viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}
