package de.abstractolotl.aztube;

import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class AzTubeChannel {

    public interface Calls {
        String downloadVideo(DownloadRequest request) throws Exception;
    }

    public static final String CHANNEL = "de.abstractolotl.aztube/youtube";
    private final ExecutorService executorService = Executors.newCachedThreadPool();

    private final MethodChannel channel;
    private final Calls calls;


    public AzTubeChannel(MethodChannel channel, Calls calls)  {
        this.calls = calls;
        this.channel = channel;

        channel.setMethodCallHandler(this::onFlutterCall);
    }

    public void sendProgressUpdate(String downloadId, double progress) {
        var args = new HashMap<String, Object>();
        args.put("downloadId", downloadId);
        args.put("progress", progress);
        new Handler(Looper.getMainLooper()).post(() -> channel.invokeMethod("progress", args));
    }

    private void onFlutterCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.equals("downloadVideo")) {
            onDownloadVideo(call, result);
        } else {
            result.error("Unknown Method", "", null);
        }
    }

    private void onDownloadVideo(MethodCall call, MethodChannel.Result result) {
        String videoId = call.argument("videoId");
        String downloadId = call.argument("downloadId");

        String qualityArg = call.argument("quality");
        qualityArg = qualityArg == null ? "" : qualityArg;
        VideoQuality videoQuality = VideoQuality.valueOf(qualityArg.toUpperCase());

        String title = call.argument("title");
        String author = call.argument("author");

        DownloadRequest request = new DownloadRequest(videoId, downloadId, videoQuality, title, author);

        executorService.submit(() -> {
            try {
                String output = calls.downloadVideo(request);
                result.success(output);
            } catch (Exception e) {
                result.error(e.getClass().getName(), e.getMessage(), null);
            }
        });
    }

}
