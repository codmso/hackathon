import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum BackgroundRemover {
    static func removeBackground(from image: UIImage) -> UIImage? {
        guard let inputImage = CIImage(image: image) else { return nil }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage)

        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return nil }

            let maskBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
            let maskImage = CIImage(cvPixelBuffer: maskBuffer)

            let filter = CIFilter.blendWithMask()
            filter.inputImage = inputImage
            filter.maskImage = maskImage
            filter.backgroundImage = CIImage.empty()

            guard let outputCIImage = filter.outputImage else { return nil }

            let context = CIContext()
            guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        } catch {
            print("Background removal failed: \(error)")
            return nil
        }
    }
}
