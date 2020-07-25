import UIKit
import CoreImage

typealias Filter = (CIImage) -> CIImage

func blur(radius: Double) -> Filter {
    return { image in
        let parameters: [String:Any] = [
            kCIInputRadiusKey: radius,
            kCIInputImageKey: image
        ]
        
        guard let filter = CIFilter(name: "CIGaussianBlur",
                                    parameters: parameters)
            else { fatalError() }
        
        guard let outputImage = filter.outputImage
            else { fatalError() }
        return outputImage
    }
}

func generate(color: UIColor) -> Filter {
    return { _ in
        let parameters = [kCIInputColorKey: CIColor(cgColor: color.cgColor)]
        guard let filter = CIFilter(name: "CIConstantColorGenerator",
                                    parameters: parameters)
            else { fatalError() }
        guard let outputImage = filter.outputImage
            else { fatalError() }
        return outputImage
    }
}

func compositeSourceOver(overlay: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: image,
            kCIInputImageKey: overlay
        ]
        
        guard let filter = CIFilter(name: "CISourceOverCompositing",
                                    parameters: parameters) else { fatalError() }
        
        guard let outputImage = filter.outputImage else { fatalError() }
        return outputImage.cropped(to: image.extent)
    }
}

func overlay(color: UIColor) -> Filter {
    return { image in
        let overlay = generate(color: color)(image).cropped(to: image.extent)
        return compositeSourceOver(overlay: overlay)(image)
    }
}

func compose(filter filter1: @escaping Filter, with filter2: @escaping Filter) -> Filter {
    return { image in filter2(filter1(image))}
}

let url = URL(string: "http://via.placeholder.com/500x500")!
let image = CIImage(contentsOf: url)!

let radius = 5.0
let color = UIColor.red.withAlphaComponent(0.2)
let blurredImage = blur(radius: radius)(image)
let overlayedImage = overlay(color: color)(blurredImage)

let blurAndOverlay = compose(filter: blur(radius: radius), with: overlay(color: color))
let result = blurAndOverlay(image)
