//
//  NetworkManager.swift
//  SCU Network Helper
//
//  Created by Terminal Void on 2026/3/15.
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var loginStatus: String = "未登录"
    @Published var isLoggingIn: Bool = false
    
    private let mainURL = "http://192.168.2.135/"
    
    private let serviceCodes: [String: String] = [
        "CHINATELECOM": "%E7%94%B5%E4%BF%A1%E5%87%BA%E5%8F%A3",
        "CHINAMOBILE": "%E7%A7%BB%E5%8A%A8%E5%87%BA%E5%8F%A3",
        "CHINAUNICOM": "%E8%81%94%E9%80%9A%E5%87%BA%E5%8F%A3",
        "EDUNET": "internet"
    ]
    
    private var session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        // 允许跟随重定向
        self.session = URLSession(configuration: config)
    }
    
    @MainActor
    func login(userId: String, pass: String, service: String) async {
        self.isLoggingIn = true
        self.loginStatus = "正在获取参数..."
        print("\n========== 🚀 开始校园网登录流程 ==========")
        
        do {
            guard let url = URL(string: mainURL) else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            
            print("1️⃣ [步骤一] 正在请求探测页面: \(url.absoluteString)")
            
            let (data, response) = try await session.data(for: request)
            
            // 打印网络响应详情
            if let httpResponse = response as? HTTPURLResponse,
                let finalURL = httpResponse.url {
                
                print("   -> 响应状态码: \(httpResponse.statusCode)")
                let finalURLString = finalURL.absoluteString
                print("   -> 最终重定向到达的 URL: \(finalURLString)")
                
                if finalURLString.contains("eportal/./success.jsp"){
                    self.loginStatus="已在线"
                    self.isLoggingIn = false
                    print("   -> ✅ 检测到设备已在线，无需重复发送登录请求。")
                    print("========== 🏁 登录流程结束 ==========\n")
                    
                    // return 极其重要：直接退出当前 login 函数，后面的步骤全都不执行了！
                    return
                    
                }
                
                
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法解析网页内容"])
            }
            
            print("   -> 成功获取网页内容，长度: \(htmlString.count) 字符")
            print("   -> 网页前200个字符: \(String(htmlString.prefix(200)).replacingOccurrences(of: "\n", with: ""))")
            
            // 2. 提取 queryString
            print("\n2️⃣ [步骤二] 尝试从网页提取 queryString...")
            guard let queryString = extractQueryString(from: htmlString) else {
                self.loginStatus = "未找到认证参数"
                self.isLoggingIn = false
                print("❌ [错误] 提取 queryString 失败！")
                print("🚨 完整的网页源码如下，请检查切割逻辑是否正确：\n\(htmlString)")
                return
            }
            print("   -> ✅ 成功提取并编码 queryString: \(queryString)")
            
            self.loginStatus = "正在验证..."
            
            // 3. 构造 POST 登录请求
            let loginPostURL = URL(string: "\(mainURL)eportal/InterFace.do?method=login")!
            var postRequest = URLRequest(url: loginPostURL)
            postRequest.httpMethod = "POST"
            postRequest.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            postRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
            
            let serviceCode = serviceCodes[service] ?? "internet"
            let postDataString = "userId=\(userId)&password=\(pass)&service=\(serviceCode)&queryString=\(queryString)&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false"
            
            postRequest.httpBody = postDataString.data(using: .utf8)
            
            print("\n3️⃣ [步骤三] 正在发送 POST 登录请求...")
            print("   -> POST 目标: \(loginPostURL.absoluteString)")
            print("   -> POST 数据: \(postDataString)")
            
            // 5. 发送 POST 登录请求
            let (loginData, loginResponse) = try await session.data(for: postRequest)
            
            if let loginHttpResponse = loginResponse as? HTTPURLResponse {
                print("   -> POST 响应状态码: \(loginHttpResponse.statusCode)")
            }
            
            // 6. 解析结果
            print("\n4️⃣ [步骤四] 解析登录结果...")
            if let loginResponseString = String(data: loginData, encoding: .utf8) {
                print("   -> 接口返回原始数据: \(loginResponseString)")
                
                if loginResponseString.contains("\"result\":\"success\"") {
                    self.loginStatus = "登录成功"
                    print("   -> 🎉 登录成功！")
                } else {
                    let errorMsg = extractErrorMessage(from: loginResponseString) ?? "未知错误"
                    self.loginStatus = "失败: \(errorMsg)"
                    print("   -> ❌ 登录被拒绝，原因: \(errorMsg)")
                }
            } else {
                print("   -> ❌ 无法将接口返回的数据解析为字符串。")
            }
            
        } catch {
            self.loginStatus = "网络异常"
            print("\n💥 [致命错误] 网络请求抛出异常:")
            print("   -> \(error.localizedDescription)")
            print("   -> 详细错误: \(error)")
        }
        
        self.isLoggingIn = false
        print("========== 🏁 登录流程结束 ==========\n")
    }
    
    // --- 辅助方法 ---
    // 完美复刻 Python: .split("/index.jsp?")[1].split("'</script>")[0]
    private func extractQueryString(from html: String) -> String? {
        let parts = html.components(separatedBy: "/index.jsp?")
        if parts.count > 1 {
            let finalParts = parts[1].components(separatedBy: "'</script>")
            if finalParts.count > 0 {
                let rawQuery = finalParts[0]
                
                // ⚠️ 修复核心：必须使用非常严格的字符集进行编码，把 & 和 = 都转义掉，
                // 否则会破坏 application/x-www-form-urlencoded 的表单结构！
                var allowedCharacters = CharacterSet.urlQueryAllowed
                allowedCharacters.remove(charactersIn: "!*'();:@&=+$,/?%#[]")
                
                return rawQuery.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? rawQuery
            }
        }
        return nil
    }
    
    private func extractErrorMessage(from jsonStr: String) -> String? {
        let parts = jsonStr.components(separatedBy: "\"message\":\"")
        if parts.count > 1 {
            let finalParts = parts[1].components(separatedBy: "\",\"")
            if finalParts.count > 0 {
                return decodeUnicode(finalParts[0])
            }
        }
        return nil
    }
    
    private func decodeUnicode(_ string: String) -> String {
        guard let data = "\"\(string)\"".data(using: .utf8) else { return string }
        do {
            return try JSONDecoder().decode(String.self, from: data)
        } catch {
            return string
        }
    }
}
