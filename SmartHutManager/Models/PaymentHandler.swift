import Foundation
import PassKit

// MARK: - Double Extension for Currency Rounding
extension Double {
    /// Rounds the double value to a valid currency format with two decimal places
    func roundedToCurrency() -> NSDecimalNumber {
        let roundedValue = (self * 100).rounded() / 100
        return NSDecimalNumber(value: roundedValue)
    }
}

// MARK: - PaymentHandler Class
class PaymentHandler: NSObject, PKPaymentAuthorizationControllerDelegate {
    private var onSuccess: (() -> Void)?
    private var onFailure: ((String) -> Void)?

    /// Initiates an Apple Pay payment
    func startPayment(
        for amount: Double,
        withMerchantIdentifier merchantIdentifier: String,
        customerName: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure

        // Create a payment request
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"

        // Validate the customer name
        let validCustomerName = customerName.isEmpty ? "Customer" : customerName
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: validCustomerName,
                amount: amount.roundedToCurrency()
            )
        ]

        // Create the payment controller
        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self

        // Present the payment interface
        paymentController.present { presented in
            if !presented {
                onFailure("Unable to present Apple Pay.")
            }
        }
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate Methods

    /// Called when the payment authorization finishes
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            // Notify failure if no success was triggered
            self.onFailure?("Payment was canceled or failed.")
        }
    }

    /// Called when the payment is authorized
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Simulate payment success (replace with your server-side payment validation logic)
        let paymentSuccess = true

        if paymentSuccess {
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            onSuccess?()
        } else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            onFailure?("Payment authorization failed.")
        }
    }
}
