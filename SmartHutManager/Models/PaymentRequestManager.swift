import Foundation
import PassKit // For Apple Pay
import MessageUI // For sending email
import UIKit

class PaymentRequestManager: NSObject, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    
    // Payment methods enum
    enum PaymentMethod {
        case applePay
        case paypal
        case zelle
    }
    
    // Function to generate and send a payment link
    func requestPayment(for customer: Customer, amount: Double, paymentMethod: PaymentMethod, from viewController: UIViewController) {
        switch paymentMethod {
        case .applePay:
            initiateApplePay(for: customer, amount: amount, from: viewController)
        case .paypal:
            sendPaymentLink(for: customer, method: .paypal, amount: amount, from: viewController)
        case .zelle:
            sendPaymentLink(for: customer, method: .zelle, amount: amount, from: viewController)
        }
    }
    
    // MARK: - Apple Pay Handling
    private func initiateApplePay(for customer: Customer, amount: Double, from viewController: UIViewController) {
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "merchant.SmarthutATL.com"
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex,]
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"
        
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: customer.name ?? "Unknown Customer", amount: NSDecimalNumber(value: amount))
        ]
        
        let paymentAuthorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
        paymentAuthorizationViewController?.delegate = viewController as? PKPaymentAuthorizationViewControllerDelegate
        
        if let vc = paymentAuthorizationViewController {
            viewController.present(vc, animated: true, completion: nil)
        } else {
            print("Error presenting Apple Pay.")
        }
    }
    
    // MARK: - PayPal and Zelle Link Handling
    private func sendPaymentLink(for customer: Customer, method: PaymentMethod, amount: Double, from viewController: UIViewController) {
        let paymentService = (method == .paypal) ? "PayPal" : "Zelle"
        
        let messageBody = """
        Hi \(customer.name ?? "Customer"),
        
        You owe $\(String(format: "%.2f", amount)).
        
        Please use the following \(paymentService) link to pay:
        
        \(generatePaymentLink(for: customer, method: method, amount: amount))
        
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
            let alert = UIAlertController(title: "Mail not available", message: "Please configure a mail account to send payment requests.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Generate Payment Link (For PayPal/Zelle)
    private func generatePaymentLink(for customer: Customer, method: PaymentMethod, amount: Double) -> String {
        switch method {
        case .paypal:
            return "https://www.paypal.me/yourbusiness/\(String(format: "%.2f", amount))"
        case .zelle:
            return "https://zellepay.com/pay/your-email-or-phone"
        default:
            return ""
        }
    }
    
    // MARK: - Mail and Message Delegate Methods
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
