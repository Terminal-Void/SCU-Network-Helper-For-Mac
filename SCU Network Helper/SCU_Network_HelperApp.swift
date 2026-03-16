//
//  SCU_Network_HelperApp.swift
//  SCU Network Helper
//
//  Created by Terminal Void on 2026/3/15.
//

import SwiftUI

@main
struct SCU_Network_HelperApp: App {
    
    init() {
        // 启动时静默读取一次密码，提前触发系统的 Keychain 授权弹窗
        // 我们不需要接收它的返回值，只是为了触发系统的权限校验
        _ = KeychainHelper.standard.readPassword()
    }
    
    var body: some Scene {
        // MenuBarExtra 依然是入口
        MenuBarExtra("校园网辅助", systemImage: "wifi") {
            // 直接放入我们接下来要写的自定义面板视图
            PopoverContentView()
        }
        // 🌟 核心魔法：将默认的“下拉菜单”样式改为“弹出面板”样式
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}
