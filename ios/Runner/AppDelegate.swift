import UIKit
import Flutter
import WebKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private let CHANNEL = "ln_reader/native";
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
        ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        registerMethodChannel();
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func registerMethodChannel() {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel.init(name: CHANNEL, binaryMessenger: controller)
        
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getCookies" {
                self.getCookies(call, result)
            } else if call.method == "clearCookies" {
                self.clearCookies()
            }
        })
    }
    
    private func getCookies(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        var cookieMap = [String: String]()
        let url = call.arguments as? String
        if (url == nil) {
            result(cookieMap)
            return
        }
        let host = URL(string: url!)?.host
        if (host == nil) {
            result(cookieMap)
            return
        }
        if #available(iOS 11.0, *) {
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
                cookies.forEach({ (cookie) in
                    if cookie.domain.contains(host!) {
                        cookieMap[cookie.name] = cookie.value
                    }
                })
                result(cookieMap)
            }
        } else {
            print("cookie store unsupported on iOS <11.0")
            result(cookieMap);
            // Fallback on earlier versions
        }
    }
    
    private func clearCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        print("[WebCacheCleaner] All cookies deleted")
        
        if #available(iOS 9.0, *) {
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                records.forEach { record in
                    WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                    print("[WebCacheCleaner] Record \(record) deleted")
                }
            }
        } else {
            print("Unabled to delete data on iOS < 9.0")
            // Fallback on earlier versions
        }
    }
}
