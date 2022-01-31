import Foundation
import Combine
import MetaWear
import simd

public enum SensorStreamForCoreML: String, MenuOption {
    case quaternionDeltas
    case quaternion
    case accelerometer50hz

    func streamPublisher(for metawear: MetaWear?) -> AnyPublisher<[Float],MWError>? {
        let base = metawear?
            .publishWhenConnected()
            .first()

        switch self {
            case .accelerometer50hz:
                return base?
                    .stream(.accelerometer(rate: .hz50, gravity: .g16))
                    .map(\.value)
                    .map(\.linearArray)
                    .share()
                    .eraseToAnyPublisher()

            case .quaternion:
                return base?
                    .stream(.sensorFusionQuaternion(mode: .ndof))
                    .map(\.value)
                    .map(\.linearArray)
                    .share()
                    .eraseToAnyPublisher()

            case .quaternionDeltas:
                return base?
                    .stream(.sensorFusionQuaternion(mode: .ndof))
                    .map(\.value)
                    .map(simd_quatf.init(vector:))
                    .scan(simd_quatf(), { prior, current in
                        if prior == simd_quatf() { return current }
                        else { return current * prior.inverse }
                    })
                    .map(\.vector)
                    .map(\.linearArray)
                    .share()
                    .eraseToAnyPublisher()
        }
    }
}
