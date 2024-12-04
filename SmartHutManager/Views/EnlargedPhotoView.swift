import SwiftUI

struct EnlargedPhotoView: View {
    @Binding var enlargedPhoto: UIImage?
    var animation: Namespace.ID

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Use `withAnimation` for smoother animations
                    withAnimation(.easeInOut) {
                        enlargedPhoto = nil
                    }
                }

            VStack {
                Spacer()

                if let enlargedPhoto = enlargedPhoto {
                    Image(uiImage: enlargedPhoto)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(20)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 10)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                self.enlargedPhoto = nil
                            }
                        }
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut) {
                        enlargedPhoto = nil
                    }
                }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                .padding(.bottom, 30)
            }
        }
        // Removed deprecated `.animation(.easeInOut)` modifier
        .transition(.opacity)
    }
}
