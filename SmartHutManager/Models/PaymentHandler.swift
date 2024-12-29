import Foundation
import PassKit


extension Double {
    /// Rounds the double value to a valid currency format with two decimal places
    func roundedToCurrency() -> NSDecimalNumber {
        let roundedValue = (self * 100).rounded() / 100
        return NSDecimalNumber(value: roundedValue)
    }
}

class PaymentHandler: NSObject, PKPaymentAuthorizationControllerDelegate {
    private var onSuccess: (() -> Void)?
    private var onFailure: ((String) -> Void)?

    func startPayment(
        for amount: Double,
        withMerchantIdentifier merchantIdentifier: String,
        customerName: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure

        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex]
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"

        let validCustomerName = customerName.isEmpty ? "Customer" : customerName
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: validCustomerName,
                amount: amount.roundedToCurrency()
            )
        ]

        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self

        paymentController.present { presented in
            if !presented {
                onFailure("Unable to present Apple Pay.")
            }
        }
    }

    // MARK: - PKPaymentAuthorizationControllerDelegate

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            self.onFailure?("Payment was canceled or failed.")
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Simulate payment success
        let paymentSuccess = true // Replace with your payment validation logic

        if paymentSuccess {
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            onSuccess?()
        } else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            onFailure?("Payment authorization failed.")
        }
    }
}
