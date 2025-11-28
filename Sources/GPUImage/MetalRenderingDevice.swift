import Foundation
import Metal
import MetalPerformanceShaders

public let sharedMetalRenderingDevice = MetalRenderingDevice()

public class MetalRenderingDevice {
    // MTLDevice
    // MTLCommandQueue

    public private(set) var device: MTLDevice
    public private(set) var commandQueue: MTLCommandQueue
    public private(set) var shaderLibrary: MTLLibrary
    public private(set) var metalPerformanceShadersAreSupported: Bool
    public private(set) var passthroughRenderState: MTLRenderPipelineState
    public private(set) var colorSwizzleRenderState: MTLRenderPipelineState
    
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

    // Allow host apps to override the GPUImage device/queue/library to match their renderer.
    public func overrideDevice(_ externalDevice: MTLDevice) {
        guard device.registryID != externalDevice.registryID else { return }
        device = externalDevice
        guard let queue = externalDevice.makeCommandQueue() else { return }
        commandQueue = queue
        if #available(iOS 9, macOS 10.13, *) {
            metalPerformanceShadersAreSupported = MPSSupportsMTLDevice(externalDevice)
        } else {
            metalPerformanceShadersAreSupported = false
        }
        guard let lib = try? externalDevice.makeDefaultLibrary(bundle: Bundle.module) else { return }
        shaderLibrary = lib
        passthroughRenderState = MetalRenderingDevice.makeRenderPipelineState(
            device: externalDevice,
            library: lib,
            vertexFunctionName: "oneInputVertex",
            fragmentFunctionName: "passthroughFragment",
            operationName: "Passthrough")
        colorSwizzleRenderState = MetalRenderingDevice.makeRenderPipelineState(
            device: externalDevice,
            library: lib,
            vertexFunctionName: "oneInputVertex",
            fragmentFunctionName: "colorSwizzleFragment",
            operationName: "ColorSwizzle")
    }
}
