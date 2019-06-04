package me.sedlar.ln_reader;

import android.os.Bundle;
import android.webkit.CookieManager;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

  private static final String CHANNEL = "ln_reader/native";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    registerMethodChannel();
  }

  private void registerMethodChannel() {
    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            (call, result) -> {
              if (call.method.equals("getCookies")) {
                getCookies(call, result);
              }
            });
  }

  private void getCookies(MethodCall methodCall, MethodChannel.Result result) {
    String url = (String) methodCall.arguments;
    String cookie = CookieManager.getInstance().getCookie(url);
    if (cookie != null) {
      Map<String, String> cookies = new HashMap<>();
      String[] cookieArray = cookie.split(";");
      for (String cookieString : cookieArray) {
        int eqIdx = cookieString.indexOf('=');
        String name = cookieString.substring(0, eqIdx).trim();
        String value = cookieString.substring(eqIdx + 1);
        cookies.put(name, value);
      }
      result.success(cookies);
    } else {
      result.success(Collections.emptyMap());
    }
  }
}
