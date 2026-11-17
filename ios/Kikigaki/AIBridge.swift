import Foundation
import WebKit
#if canImport(FoundationModels)
import FoundationModels
#endif

/// 画面(JavaScript)からの依頼を受けて、iPhone の中の AI に文章を書かせる。
/// 画面側: await window.webkit.messageHandlers.kikigaki.postMessage({ type, prompt, max })
///   type "status" → { ok, available, reason }
///   type "text"   → { ok, text }  失敗時は { ok:false, code, reason }
final class AIBridge: NSObject, WKScriptMessageHandlerWithReply {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else {
            replyHandler(["ok": false, "code": "bad_request"], nil)
            return
        }
        let prompt = body["prompt"] as? String ?? ""
        let maxTokens = (body["max"] as? NSNumber)?.intValue ?? 200

        Task { @MainActor in
            let result: [String: Any]
            switch type {
            case "status": result = AIEngine.status()
            case "text": result = await AIEngine.generate(prompt: prompt, maxTokens: maxTokens)
            default: result = ["ok": false, "code": "bad_request"]
            }
            replyHandler(result, nil)
        }
    }
}

enum AIEngine {
    /// この iPhone で端末内の AI が使えるか
    static func status() -> [String: Any] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return ["ok": true, "available": true]
            case .unavailable(.deviceNotEligible):
                return ["ok": true, "available": false, "reason": "このiPhoneは、端末内のAI（Apple Intelligence）に対応していません。"]
            case .unavailable(.appleIntelligenceNotEnabled):
                return ["ok": true, "available": false, "reason": "「設定」→「Apple IntelligenceとSiri」で、Apple Intelligence をオンにしてください。"]
            case .unavailable(.modelNotReady):
                return ["ok": true, "available": false, "reason": "AIを準備しています。Wi-Fiにつないで、しばらくしてからもう一度開いてください。"]
            case .unavailable:
                return ["ok": true, "available": false, "reason": "いまは端末内のAIを使えません。"]
            }
        }
        #endif
        return ["ok": true, "available": false, "reason": "端末内のAIは、iOS 26 以降の対応機種で使えます。"]
    }

    /// 一回の依頼ごとに新しい会話として書かせる(端末内AIは一度に覚えられる量が小さいため)
    static func generate(prompt: String, maxTokens: Int) async -> [String: Any] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard case .available = SystemLanguageModel.default.availability else {
                return ["ok": false, "code": "unavailable"]
            }
            do {
                let session = LanguageModelSession()
                let options = GenerationOptions(temperature: 0.6, maximumResponseTokens: maxTokens)
                let response = try await session.respond(to: prompt, options: options)
                return ["ok": true, "text": response.content]
            } catch {
                return ["ok": false, "code": "failed", "reason": String(describing: error)]
            }
        }
        #endif
        return ["ok": false, "code": "unavailable"]
    }
}
