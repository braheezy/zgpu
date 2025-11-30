#include "dawn/native/DawnNative.h"
#include "webgpu/webgpu_glfw.h"
#include <assert.h>
#include <stdio.h>
#include <vector>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct DawnNativeInstanceImpl* DawnNativeInstance;

static std::vector<dawn::native::Adapter> g_adapters;
static WGPUSurface g_surface = nullptr;

DawnNativeInstance dniCreate(void) {
    return reinterpret_cast<DawnNativeInstance>(new dawn::native::Instance());
}

void dniDestroy(DawnNativeInstance dni) {
    assert(dni);
    delete reinterpret_cast<dawn::native::Instance*>(dni);
    g_adapters.clear();
    g_surface = nullptr;
}

WGPUInstance dniGetWgpuInstance(DawnNativeInstance dni) {
    assert(dni);
    return reinterpret_cast<dawn::native::Instance*>(dni)->Get();
}

void dniDiscoverDefaultAdapters(DawnNativeInstance dni) {
    assert(dni);
    dawn::native::Instance* instance = reinterpret_cast<dawn::native::Instance*>(dni);
    WGPURequestAdapterOptions options = {};
    options.powerPreference = WGPUPowerPreference_HighPerformance;
    options.backendType = WGPUBackendType_Undefined;
    options.forceFallbackAdapter = false;
    options.compatibleSurface = g_surface;  // Use the stored surface for compatibility
    g_adapters = instance->EnumerateAdapters(&options);
}

void dniSetSurface(WGPUSurface surface) {
    g_surface = surface;
}

WGPUSurface dniGetSurface(void) {
    return g_surface;
}

WGPUSurface dniCreateSurfaceForWindow(DawnNativeInstance dni, void* glfw_window) {
    assert(dni);
    WGPUInstance instance = reinterpret_cast<dawn::native::Instance*>(dni)->Get();
    g_surface = wgpuGlfwCreateSurfaceForWindow(instance, (GLFWwindow*)glfw_window);
    return g_surface;
}

WGPUAdapter dniGetAdapter(void) {
    if (g_adapters.empty()) {
        return nullptr;
    }
    return g_adapters[0].Get();
}

WGPUDevice dniCreateDevice(const WGPUDeviceDescriptor* descriptor) {
    if (g_adapters.empty()) {
        return nullptr;
    }
    return g_adapters[0].CreateDevice(descriptor);
}

const DawnProcTable* dnGetProcs(void) {
    return &dawn::native::GetProcs();
}

void dniConfigureSurface(WGPUSurface surface, const WGPUSurfaceConfiguration* config) {
    const DawnProcTable& procs = dawn::native::GetProcs();
    procs.surfaceConfigure(surface, config);
}

#ifdef __cplusplus
}
#endif
