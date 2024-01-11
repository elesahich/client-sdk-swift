/*
 * Copyright 2022 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import CoreImage

#if canImport(ReplayKit)
import ReplayKit
#endif

extension CIImage {

    /// Convenience method to convert ``CIImage`` to ``CVPixelBuffer``
    /// since ``CIImage/pixelBuffer`` is not always available.
    public func toPixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?

        // get current size
        let size: CGSize = extent.size

        // default options
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
        ] as [String: Any]

        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault,
                                                   Int(size.width),
                                                   Int(size.height),
                                                   kCVPixelFormatType_32BGRA,
                                                   options as CFDictionary,
                                                   &pixelBuffer)

        let ciContext = CIContext()

        if let pixelBuffer = pixelBuffer, status == kCVReturnSuccess {
            ciContext.render(self, to: pixelBuffer)
        }

        return pixelBuffer
    }
}

extension CGImage {

    /// Convenience method to convert ``CGImage`` to ``CVPixelBuffer``
    public func toPixelBuffer(pixelFormatType: OSType = kCVPixelFormatType_32ARGB,
                              colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB(),
                              alphaInfo: CGImageAlphaInfo = .noneSkipFirst) -> CVPixelBuffer? {

        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         pixelFormatType,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)

        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }

        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
            return nil
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }

        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: alphaInfo.rawValue)
        else {
            return nil
        }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelBuffer
    }
}

import Promises

#if os(iOS)
@available(iOS 12, *)
extension RPSystemBroadcastPickerView {
    public static func createPickerView(
        for preferredExtension: String?,
        showsMicrophoneButton: Bool
    ) -> Promise<RPSystemBroadcastPickerView> {
        return Promise<RPSystemBroadcastPickerView>(on: DispatchQueue.main) { fulfill, error in
            assert(Thread.current.isMainThread, "must be called on main thread")
            
            let pickerView = RPSystemBroadcastPickerView()
            
            pickerView.preferredExtension = preferredExtension
            pickerView.showsMicrophoneButton = showsMicrophoneButton
            
            let selector = NSSelectorFromString("buttonPressed:")
            if pickerView.responds(to: selector) {
                pickerView.perform(selector, with: nil)
            }
            
            fulfill(pickerView)
        }
    }
    
    public func onScreenShareButtonTapped() -> Promise<Void> {
        // Must be called on main thread
        return Promise<Void>(on: DispatchQueue.main) { fulfill, error in
            for subview in self.subviews {
                if let button = subview as? UIButton {
                    button.addAction {
                        fulfill(Void())
                    }
                }
            }
        }
    }
}
#endif

import UIKit

extension UIControl {
  func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping () -> Void) {
    addAction(UIAction { (action: UIAction) in closure() }, for: controlEvents)
  }
}
