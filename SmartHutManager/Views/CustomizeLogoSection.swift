import SwiftUI
import PhotosUI

struct CustomizeLogoSection: View {
    @Binding var selectedLogo: UIImage?
    @Binding var isShowingImagePicker: Bool

    var body: some View {
        Section(header: Text("Custom Branding")) {
            Button(action: {
                isShowingImagePicker.toggle()
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                    Text("Replace Splash Screen Logo")
                        .font(.body)
                    Spacer()
                    if let selectedLogo = selectedLogo {
                        Image(uiImage: selectedLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
