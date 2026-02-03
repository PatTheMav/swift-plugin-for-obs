import Foundation

class SwiftPlugin {
  let name: String
  var modulePointer: UnsafeMutableRawPointer?
  var moduleLookup: OpaquePointer?

  init(name: String) {
    self.name = name
  }

  func getRetained() -> OpaquePointer {
    let retained = Unmanaged.passRetained(self).toOpaque()

    return OpaquePointer(retained)
  }

  func getUnretained() -> OpaquePointer {
    let unretained = Unmanaged.passUnretained(self).toOpaque()

    return OpaquePointer(unretained)
  }
}

struct SwiftSource {
  let id: String
  let type: obs_source_type
  let flags: UInt32
  let iconType: obs_icon_type
  var getName: (_ data: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>?
  var create: (_ settings: OpaquePointer?, _ source: OpaquePointer?) -> UnsafeMutableRawPointer?
  var destroy: (_ data: UnsafeMutableRawPointer?) -> Void

  var getWidth: (_ data: UnsafeMutableRawPointer?) -> UInt32
  var getHeight: (_ data: UnsafeMutableRawPointer?) -> UInt32

  var videoTick: (_ data: UnsafeMutableRawPointer?, _: Float32) -> Void
  var videoRender: (_ data: UnsafeMutableRawPointer?, _ effect: OpaquePointer?) -> Void

  var getDefaults: (_ data: OpaquePointer?) -> Void
  var getProperties: (_ data: UnsafeMutableRawPointer?) -> OpaquePointer?

  var update: (_ data: UnsafeMutableRawPointer?, _ settings: OpaquePointer?) -> Void
}

nonisolated(unsafe) private let boxRender = SwiftSource(
  id: "box_render",
  type: OBS_SOURCE_TYPE_INPUT,
  flags: UInt32(OBS_SOURCE_VIDEO | OBS_SOURCE_CUSTOM_DRAW | OBS_SOURCE_SRGB),
  iconType: OBS_ICON_TYPE_DESKTOP_CAPTURE,
  getName: { data in
    return obs_module_text("BoxRender".cString(using: .utf8)!)
  },
  create: { settings, source in
    OBSLog(.info, "Would create now...")

    var sourceData = "Some Data"

    var data = UnsafeMutableRawPointer.allocate(
      byteCount: sourceData.lengthOfBytes(using: .utf8), alignment: MemoryLayout<UInt8>.alignment)

    sourceData.withUTF8 { body in
      data.copyMemory(from: body.baseAddress!, byteCount: body.count)
    }

    return data
  },
  destroy: { data in
    guard let data else { return }

    let stringData = data.assumingMemoryBound(to: UInt8.self)

    let string = String(cString: stringData)

    data.deallocate()
  },
  getWidth: { data in
    return 64
  },
  getHeight: { data in
    return 64
  },
  videoTick: { data, time in
    guard let data else { return }
    let stringData = data.assumingMemoryBound(to: UInt8.self)

    let string = String(cString: stringData)
  },
  videoRender: { data, effect in
    guard let data else { return }
    let stringData = data.assumingMemoryBound(to: UInt8.self)

    let string = String(cString: stringData)
  },
  getDefaults: { settings in
    let key = "someKey"
    let value = "someValue"

    key.withCString { keyString in
      value.withCString { valueString in
        obs_data_set_default_string(settings, keyString, valueString)
      }
    }
  },
  getProperties: { data in
    guard let properties = obs_properties_create() else {
      return nil
    }

    let name = "someBool"
    let description = "someDescription"

    name.withCString { namePointer in
      description.withCString { descriptionPointer in
        let _ = obs_properties_add_bool(properties, namePointer, descriptionPointer)
      }
    }

    return properties
  },
  update: { data, settings in
    guard let data else { return }
    let stringData = data.assumingMemoryBound(to: UInt8.self)

    let string = String(cString: stringData)
  }
)

@_cdecl("box_get_name")
func box_get_name(_ data: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>? {
  return boxRender.getName(data)
}

@_cdecl("box_create")
func box_create(_ settings: OpaquePointer?, _ source: OpaquePointer?) -> UnsafeMutableRawPointer? {
  return boxRender.create(settings, source)
}

@_cdecl("box_destroy")
func box_destroy(_ data: UnsafeMutableRawPointer?) {
  return boxRender.destroy(data)
}

@_cdecl("box_video_tick")
func box_video_tick(_ data: UnsafeMutableRawPointer?, _ seconds: Float32) {
  return boxRender.videoTick(data, seconds)
}

@_cdecl("box_video_render")
func box_video_render(_ data: UnsafeMutableRawPointer?, _ effect: OpaquePointer?) {
  return boxRender.videoRender(data, effect)
}

@_cdecl("box_get_width")
func box_get_width(_ data: UnsafeMutableRawPointer?) -> UInt32 {
  return boxRender.getWidth(data)
}

@_cdecl("box_get_height")
func box_get_height(_ data: UnsafeMutableRawPointer?) -> UInt32 {
  return boxRender.getHeight(data)
}

@_cdecl("box_get_defaults")
func box_get_defaults(_ settings: OpaquePointer?) {
  return boxRender.getDefaults(settings)
}

@_cdecl("box_get_properties")
func box_get_properties(_ data: UnsafeMutableRawPointer?) -> OpaquePointer? {
  return boxRender.getProperties(data)
}

@_cdecl("box_update")
func box_update(_ data: UnsafeMutableRawPointer?, _ settings: OpaquePointer?) {
  return boxRender.update(data, settings)
}

nonisolated(unsafe) private let instance: SwiftPlugin = SwiftPlugin(name: "SwiftPlugin")

public enum OBSLogLevel: Int32 {
  case error = 100
  case warning = 200
  case info = 300
  case debug = 400
}

@inlinable
public func OBSLog(_ level: OBSLogLevel, _ format: String, _ args: CVarArg...) {
  let logMessage = String.localizedStringWithFormat(format, args)

  logMessage.withCString { cMessage in
    withVaList([cMessage]) { arguments in
      blogva(level.rawValue, "[Swift Plugin for OBS] %s", arguments)
    }
  }
}

@_cdecl("obs_module_set_pointer")
func obs_module_set_pointer(_ module: UnsafeMutableRawPointer) {
  instance.modulePointer = module
}

@_cdecl("obs_current_module")
func obs_current_module() -> OpaquePointer? {
  guard let pointer = instance.modulePointer else {
    return nil
  }

  return OpaquePointer(pointer)
}

@_cdecl("obs_module_ver")
func obs_module_ver() -> UInt32 {
  return libobsApiVersion
}

@_cdecl("obs_module_text")
func obs_module_text(_ val: UnsafePointer<CChar>) -> UnsafePointer<CChar>? {
  guard let lookup = instance.moduleLookup else {
    return nil
  }

  let output = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: 1)

  text_lookup_getstr(lookup, val, output)

  return output.pointee
}

@_cdecl("obs_module_get_string")
func obs_module_get_string(
  val: UnsafePointer<CChar>, out: UnsafeMutablePointer<UnsafePointer<CChar>?>
) -> Bool {
  guard let lookup = instance.moduleLookup else {
    return false
  }

  return text_lookup_getstr(lookup, val, out)
}

@_cdecl("obs_module_set_locale")
func obs_module_set_locale(locale: UnsafePointer<CChar>) {
  if instance.moduleLookup != nil {
    text_lookup_destroy(instance.moduleLookup)
  }

  instance.moduleLookup = obs_module_load_locale(obs_current_module(), "en-US", locale)
}

@_cdecl("obs_module_free_locale")
func obs_module_free_locale() {
  guard let lookup = instance.moduleLookup else {
    return
  }

  text_lookup_destroy(lookup)
  instance.moduleLookup = nil
}

@_cdecl("obs_module_load")
func obs_module_load() -> Bool {
  var boxRenderInfo = obs_source_info()

  let boxId = "Box_Render"

  boxId.withCString {
    boxRenderInfo.id = $0
    boxRenderInfo.type = OBS_SOURCE_TYPE_INPUT
    boxRenderInfo.get_name = box_get_name
    boxRenderInfo.create = box_create
    boxRenderInfo.destroy = box_destroy
    boxRenderInfo.output_flags = boxRender.flags
    boxRenderInfo.video_tick = box_video_tick
    boxRenderInfo.video_render = box_video_render
    boxRenderInfo.get_width = box_get_width
    boxRenderInfo.get_height = box_get_height
    boxRenderInfo.get_defaults = box_get_defaults
    boxRenderInfo.get_properties = box_get_properties
    boxRenderInfo.update = box_update
    boxRenderInfo.icon_type = boxRender.iconType

    withUnsafePointer(to: boxRenderInfo) {
      obs_register_source_s($0, MemoryLayout<obs_source_info>.size)
    }
  }

  OBSLog(.info, "Loaded successfully (version \(PluginMeta.versionString))")
  return true
}

@_cdecl("obs_module_unload")
func obs_module_unload() {
  OBSLog(.info, "Unloaded")
}
