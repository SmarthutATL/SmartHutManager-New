import SwiftUI
import UIKit

// Custom UITextView Wrapper without Toolbar
struct CustomTextView: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.delegate = context.coordinator
        
        // Listen for keyboard appearance/disappearance
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextView
        var doneButton: UIButton?

        init(_ parent: CustomTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        @objc func keyboardWillShow(notification: NSNotification) {
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            
            // Add a 'Done' button above the keyboard
            if doneButton == nil {
                doneButton = UIButton(type: .system)
                doneButton?.setTitle("Done", for: .normal)
                doneButton?.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
                doneButton?.backgroundColor = UIColor.systemGray5
                doneButton?.setTitleColor(.systemBlue, for: .normal)
                doneButton?.frame = CGRect(
                    x: keyboardFrame.width - 80,
                    y: keyboardFrame.origin.y - 40,
                    width: 70,
                    height: 30
                )
                
                // Get the window from the active scene
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.addSubview(doneButton!)
                }
            }
        }
        
        @objc func keyboardWillHide(notification: NSNotification) {
            // Remove the done button when the keyboard is hidden
            doneButton?.removeFromSuperview()
            doneButton = nil
        }
        
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
