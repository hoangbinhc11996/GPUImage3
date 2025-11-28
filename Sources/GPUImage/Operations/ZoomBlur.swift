public class ZoomBlur: BasicOperation {
    public var blurSize: Float = 1.0 {
        didSet {
            if blurSize < 0 { blurSize = 0; return }
            updateUniforms()
        }
    }

    public var blurCenter: Position = Position.center {
        didSet { updateUniforms() }
    }

    private var inverseImageSize: (x: Float, y: Float) = (1.0, 1.0)

    public init() {
        super.init(fragmentFunctionName: "zoomBlurFragment", numberOfInputs: 1)
        updateUniforms()
    }

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        updateImageSize(using: texture)
        super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex)
    }

    private func updateImageSize(using texture: Texture) {
        let rotation = texture.orientation.rotationNeeded(for: .portrait)
        let outputWidth = rotation.flipsDimensions() ? texture.texture.height : texture.texture.width
        let outputHeight = rotation.flipsDimensions() ? texture.texture.width : texture.texture.height
        guard outputWidth > 0 && outputHeight > 0 else { return }

        inverseImageSize = (1.0 / Float(outputWidth), 1.0 / Float(outputHeight))
        updateUniforms()
    }

    private func updateUniforms() {
        uniformSettings["center"] = blurCenter
        let minInv = min(inverseImageSize.x, inverseImageSize.y)
        uniformSettings["size"] = blurSize * minInv
    }
}
