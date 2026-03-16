//
//  KeychainHelper.swift
//  SCU Network Helper
//
//  Created by Terminal Void on 2026/3/16.
//

import Foundation
import Security

class KeychainHelper {
    // 单例模式，全局调用
    static let standard = KeychainHelper()
    
    // 我们定义一个统一的服务名和账号名，用来在钥匙串里定位你的密码
    private let service = "SCUNetworkHelper"
    private let account = "CampusNetPassword"
    
    private init() {}
    
    // 🌟 保存密码
    func save(_ password: String) {
        guard let data = password.data(using: .utf8) else { return }
        
        // 1. 先准备好查询条件
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // 2. 检查是不是已经存过密码了
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // 如果存过，就更新它
            let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
            SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        } else {
            // 如果没存过，就新建一个
            var newItem = query
            newItem[kSecValueData as String] = data
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }
    
    // 🌟 读取密码
    func readPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true, // 告诉系统我们要拿真实的数据
            kSecMatchLimit as String: kSecMatchLimitOne // 只拿一条
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    // 🌟 删除密码 (预留接口，如果你以后想加个“注销”按钮)
    func deletePassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
