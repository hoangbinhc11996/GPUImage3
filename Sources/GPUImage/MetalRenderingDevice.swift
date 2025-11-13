import Foundation
import Metal
import MetalPerformanceShaders

public let sharedMetalRenderingDevice = MetalRenderingDevice()

public class MetalRenderingDevice {
    // MTLDevice
    // MTLCommandQueue

    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let shaderLibrary: MTLLibrary
    public let metalPerformanceShadersAreSupported: Bool
    public let passthroughRenderState: MTLRenderPipelineState
    public let colorSwizzleRenderState: MTLRenderPipelineState
    
    private static func makeRenderPipelineState(
        device: MTLDevice,
        library: MTLLibrary,
        vertexFunctionName: String,
        fragmentFunctionName: String,
        operationName: String
    ) -> MTLRenderPipelineState {
        guard let vertexFunction = library.makeFunction(name: vertexFunctionName) else {
            fatalError("\(operationName): could not compile vertex function \(vertexFunctionName)")
        }
        guard let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else {
            fatalError("\(operationName): could not compile fragment function \(fragmentFunctionName)")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.rasterSampleCount = 1
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Could not create render pipeline state for vertex:\(vertexFunctionName), fragment:\(fragmentFunctionName), error:\(error)")
        }
    }

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Could not create Metal Device")
        }
        self.device = device

        guard let queue = self.device.makeCommandQueue() else {
            fatalError("Could not create command queue")
        }
        self.commandQueue = queue

        if #available(iOS 9, macOS 10.13, *) {
            self.metalPerformanceShadersAreSupported = MPSSupportsMTLDevice(device)
        } else {
            self.metalPerformanceShadersAreSupported = false
        }

        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle.module) else {
            fatalError("Could not load library")
        }

        self.shaderLibrary = defaultLibrary
        
        self.passthroughRenderState = MetalRenderingDevice.makeRenderPipelineState(
            device: self.device,
            library: self.shaderLibrary,
            vertexFunctionName: "oneInputVertex",
            fragmentFunctionName: "passthroughFragment",
            operationName: "Passthrough")
        
        self.colorSwizzleRenderState = MetalRenderingDevice.makeRenderPipelineState(
            device: self.device,
            library: self.shaderLibrary,
            vertexFunctionName: "oneInputVertex",
            fragmentFunctionName: "colorSwizzleFragment",
            operationName: "ColorSwizzle")
    }
}
