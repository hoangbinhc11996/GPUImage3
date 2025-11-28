import Foundation

public class MotionBlur: BasicOperation {
    public var blurSize: Float = 2.5 {
        didSet {
            if blurSize < 0 { blurSize = 0; return }
            updateDirectionalStep()
        }
    }
    public var blurAngle: Float = 0.0 {
        didSet { updateDirectionalStep() }
    }

    private var lastOutputDimensions: (width: Int, height: Int)?

    public init() {
        super.init(fragmentFunctionName: "motionBlurFragment", numberOfInputs: 1)
        uniformSettings["directionalTexelStep"] = Position.zero
    }

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        updateDirectionalStep(using: texture)
        super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex)
    }

    private func updateDirectionalStep(using texture: Texture) {
        let rotation = texture.orientation.rotationNeeded(for: .portrait)
        let outputWidth = rotation.flipsDimensions() ? texture.texture.height : texture.texture.width
        let outputHeight = rotation.flipsDimensions() ? texture.texture.width : texture.texture.height
        lastOutputDimensions = (outputWidth, outputHeight)

        updateDirectionalStep()
    }

    private func updateDirectionalStep() {
        guard let dims = lastOutputDimensions, dims.width > 0, dims.height > 0 else {
            uniformSettings["directionalTexelStep"] = Position.zero
            return
        }

        let angleRadians = blurAngle * .pi / 180
        let stepX = cos(angleRadians) * blurSize / Float(dims.width)
        let stepY = sin(angleRadians) * blurSize / Float(dims.height)
        uniformSettings["directionalTexelStep"] = Position(stepX, stepY)
    }
}
