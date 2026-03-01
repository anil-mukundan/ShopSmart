import CoreLocation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let clManager = CLLocationManager()
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var currentLocation: CLLocation?

    override init() {
        authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            clManager.startUpdatingLocation()
        }
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestPermission() {
        clManager.requestWhenInUseAuthorization()
    }

    // MARK: - Sorting

    func sorted(_ stores: [StoreModel]) -> [StoreModel] {
        guard let current = currentLocation else {
            return stores.sorted { $0.name < $1.name }
        }
        let withLocation = stores
            .filter { $0.latitude != nil && $0.longitude != nil }
            .sorted {
                let la = CLLocation(latitude: $0.latitude!, longitude: $0.longitude!)
                let lb = CLLocation(latitude: $1.latitude!, longitude: $1.longitude!)
                return current.distance(from: la) < current.distance(from: lb)
            }
        let withoutLocation = stores
            .filter { $0.latitude == nil || $0.longitude == nil }
            .sorted { $0.name < $1.name }
        return withLocation + withoutLocation
    }

    // MARK: - Distance display

    func distanceString(to store: StoreModel) -> String? {
        guard let current = currentLocation,
              let lat = store.latitude,
              let lon = store.longitude else { return nil }
        let meters = current.distance(from: CLLocation(latitude: lat, longitude: lon))
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: measurement)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized { clManager.startUpdatingLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}
