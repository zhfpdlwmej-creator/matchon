package com.jacob.matchon.web;

import com.jacob.matchon.notification.WebPushService;
import com.jacob.matchon.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** 웹 푸시 구독 REST API. */
@RestController
@RequestMapping("/api/push")
@RequiredArgsConstructor
public class PushController {

	private final WebPushService webPush;

	/** 클라이언트가 구독 시 사용할 VAPID 공개키 */
	@GetMapping("/key")
	public Map<String, Object> key() {
		return Map.of("ok", true, "key", webPush.getPublicKey());
	}

	/** 구독 등록 */
	@PostMapping("/subscribe")
	@SuppressWarnings("unchecked")
	public Map<String, Object> subscribe(@RequestBody Map<String, Object> body) {
		Long uid = CurrentUser.required();
		String endpoint = (String) body.get("endpoint");
		Map<String, String> keys = (Map<String, String>) body.get("keys");
		if (endpoint == null || keys == null) {
			throw new ApiException(400, "구독 정보가 올바르지 않습니다.");
		}
		webPush.saveSubscription(uid, endpoint, keys.get("p256dh"), keys.get("auth"));
		return Map.of("ok", true);
	}

	/** 내게 테스트 푸시 발송 */
	@PostMapping("/test")
	public Map<String, Object> test() {
		Long uid = CurrentUser.required();
		webPush.sendToUser(uid, "{\"title\":\"matchon 알림 테스트\",\"body\":\"알림이 정상 동작합니다 🎉\",\"url\":\"/\"}");
		return Map.of("ok", true);
	}
}
