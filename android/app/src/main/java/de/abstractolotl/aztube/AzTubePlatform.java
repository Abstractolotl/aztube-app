package de.abstractolotl.aztube;

import android.os.Handler;
import android.os.Looper;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.util.HashMap;

public class AzTubePlatform {

    public interface PlatformImpl {
        void downloadVideo(DownloadRequest request);
    }

    public static final String CHANNEL = "de.abstractolotl.aztube/youtube";

    private final MethodChannel platform;
    private final PlatformImpl impl;


    public AzTubePlatform(FlutterEngine flutterEngine, PlatformImpl callback)  {
        this.impl = callback;

        platform = new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL);
        platform.setMethodCallHandler(this::onFlutterCall);
    }

    public void sendProgressUpdate(String downloadId, double progress) {
        var args = new HashMap<String, Object>();
        args.put("downloadId", downloadId);
        args.put("progress", progress);
        new Handler(Looper.getMainLooper()).post(() -> platform.invokeMethod("progress", args));
    }

    private void onFlutterCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "downloadVideo":
                onDownloadVideo(call, result);
                break;
            default:
                result.error("Unknown Method", "", null);
                break;
        }
    }

    private void onDownloadVideo(MethodCall call, MethodChannel.Result result) {
        String videoId = call.argument("videoId");
        String downloadId = call.argument("downloadId");
        VideoQuality videoQuality = VideoQuality.valueOf(((String)call.argument("quality")).toUpperCase());
        String title = call.argument("title");
        String author = call.argument("author");

        DownloadRequest request = new DownloadRequest(videoId, downloadId, videoQuality, title, author);
        impl.downloadVideo(request);
        result.success("ok");
    }

}
