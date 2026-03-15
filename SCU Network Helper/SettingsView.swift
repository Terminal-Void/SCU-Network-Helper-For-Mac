//
//  SettingsView.swift
//  SCU Network Helper
//
//  Created by Terminal Void on 2026/3/15.
//

import SwiftUI

struct SettingsView: View {
    // 使用 @AppStorage 自动将数据持久化到系统的 UserDefaults 中
    @AppStorage("username") private var username = ""
    @AppStorage("password") private var password = "" // ⚠️ 仅作演示，实际应用中密码应存入 Keychain
    @AppStorage("serviceName") private var serviceName = "EDUNET"
    @AppStorage("isAutoLoginEnabled") private var isAutoLoginEnabled = false
    @AppStorage("pingAddress") private var pingAddress = "222.220.212.130"
    
    var body: some View {
        Form {
            // 账号信息区
            Section {
                TextField("学号 / 账号", text: $username)
                    .textFieldStyle(.roundedBorder)
                
                SecureField("密码", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                Picker("运营商", selection: $serviceName) {
                    Text("校园网").tag("EDUNET")
                    Text("中国电信").tag("CHINATELECOM")
                    Text("中国移动").tag("CHINAMOBILE")
                    Text("中国联通").tag("CHINAUNICOM")
                }
                .pickerStyle(.menu)
            } header: {
                Text("认证信息")
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // 自动化设置区
            Section {
                Toggle("开启断网自动重连", isOn: $isAutoLoginEnabled)
                Text("开启后，后台将每隔一段时间检测网络状态，若掉线则自动静默登录。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("检测地址", text: $pingAddress)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("自动化")
            }
            
        }
        .padding()
        // 固定窗口大小，符合 macOS 设置窗口的习惯
        .frame(width: 350, height: 350)
        .onAppear {
            // 当设置窗口出现时，强制将我们的后台应用拉到最前面
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}

//#Preview {
//SettingsView()
//
