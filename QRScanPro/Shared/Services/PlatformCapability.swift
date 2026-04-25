import Foundation

#if os(iOS)
import AVFoundation
#endif

struct PlatformCapability {
    var supportsCameraScanning: Bool {
        #if os(iOS)
        return !AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices.isEmpty
        #else
        return false
        #endif
    }

    var supportsTorch: Bool {
        #if os(iOS)
        guard let device = AVCaptureDevice.default(for: .video) else {
            return false
        }
        return device.hasTorch
        #else
        return false
        #endif
    }

    var supportsImageImport: Bool {
        true
    }

    var supportsInAppBrowser: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
}
