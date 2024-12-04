import SwiftUI

struct PhotosView: View {
    @ObservedObject var workOrder: WorkOrder

    @State private var enlargedPhoto: UIImage? = nil
    @Namespace private var animation

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack {
            // Show customer name and work order number at the top
            Text("\(workOrder.customer?.name ?? "Unknown Customer") - #\(workOrder.workOrderNumber)")
                .font(.headline)
                .padding()

            // Display photos grid if available
            if let photosData = workOrder.photos as? [Data], !photosData.isEmpty {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Array(photosData.enumerated()), id: \.offset) { index, photoData in
                            if let uiImage = UIImage(data: photoData) {
                                Button(action: {
                                    withAnimation {
                                        enlargedPhoto = uiImage
                                    }
                                }) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                        .matchedGeometryEffect(id: index, in: animation) // Use index as ID
                                }
                            } else {
                                // Handle corrupted photo
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                // Message for no photos available
                Text("No photos available")
                    .foregroundColor(.gray)
                    .padding()
            }

            // Display enlarged photo if it exists
            if enlargedPhoto != nil {
                EnlargedPhotoView(enlargedPhoto: $enlargedPhoto, animation: animation)
            }
        }
    }
}
