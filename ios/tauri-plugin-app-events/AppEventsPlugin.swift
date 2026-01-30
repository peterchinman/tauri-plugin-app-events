//
//  AppEventsPlugin.swift
//  tauri-plugin-app-events
//
//  Created by wtto on 2024/10/28.
//

import OSLog
import SwiftRs
import Tauri
import UIKit
import WebKit

let log = OSLog(subsystem: "com.tauri.dev", category: "plugin.app.events")

class SetEventHandlerArgs: Decodable {
  let handler: Channel
}

class AppEvetnsPlugin: Plugin {
  private var resumeChannel: Channel? = nil
  private var pauseChannel: Channel? = nil
  private var hasEnteredBackground = false
  private var isReady = false

  override func load(webview: WKWebView) {
    super.load(webview: webview)
    NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc func applicationDidBecomeActive(notification: NSNotification) {
    os_log(.debug, log: log, "Application Did Become Active")
    guard hasEnteredBackground, isReady else { return }
    trigger("resume", data: JSObject())
    resumeChannel?.send(JSObject())
  }

  @objc func applicationDidEnterBackground(notification: NSNotification) {
    os_log(.debug, log: log, "Application Did Enter Background")
    hasEnteredBackground = true
    guard isReady else { return }
    trigger("pause", data: JSObject())
    pauseChannel?.send(JSObject())
  }

  @objc public func setResumeHandler(_ invoke: Invoke) throws {
    os_log(.debug, log: log, "setResumeHandler")
    let args = try invoke.parseArgs(SetEventHandlerArgs.self)
    resumeChannel = args.handler
    isReady = true
    invoke.resolve()
  }

  @objc public func setPauseHandler(_ invoke: Invoke) throws {
    os_log(.debug, log: log, "setPauseHandler")
    let args = try invoke.parseArgs(SetEventHandlerArgs.self)
    pauseChannel = args.handler
    isReady = true
    invoke.resolve()
  }
}

@_cdecl("init_plugin_app_events")
func initPlugin() -> Plugin {
  return AppEvetnsPlugin()
}
