import SwiftUI
import MapKit

struct MapView: View {
    let address: String
    @State private var region = MKCoordinateRegion()
    @State private var annotationItem: Location? = nil

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: annotationItem == nil ? [] : [annotationItem!]) { location in
            MapAnnotation(coordinate: location.coordinate) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    Text("Here")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            getCoordinate(addressString: address) { coordinate, error in
                if let coordinate = coordinate {
                    region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                    annotationItem = Location(coordinate: coordinate)
                } else {
                    print("Failed to get location for address: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // Function to get coordinate from address string
    func getCoordinate(addressString: String, completion: @escaping (CLLocationCoordinate2D?, Error?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { placemarks, error in
            if let error = error {
                completion(nil, error)
            } else if let placemark = placemarks?.first, let location = placemark.location {
                completion(location.coordinate, nil)
            } else {
                completion(nil, NSError(domain: "MapErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No location found"]))
            }
        }
    }
}

struct Location: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(address: "New York, NY")
    }
}
