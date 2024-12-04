import SwiftUI

struct EnlargedReceiptsView: View {
    @Binding var enlargedReceipt: UIImage?
    var animation: Namespace.ID

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        enlargedReceipt = nil
                    }
                }

            VStack {
                Spacer()

                if let enlargedReceipt = enlargedReceipt {
                    Image(uiImage: enlargedReceipt)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(20)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 10)
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                self.enlargedReceipt = nil
                            }
                        }
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut) {
                        enlargedReceipt = nil
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
        .transition(.opacity)
    }
}
