package de.aztube.aztube_app;

import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Objects;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    public static final String CHANNEL = "de.aztube.aztube_app/youtube";
    MethodChannel channel;

    @Override
    protected void onCreate(@Nullable @org.jetbrains.annotations.Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        NotificationUtil.CreateNotificationChannel(this);
        BackgroundService.StartBackgroundService(this);

        channel = new MethodChannel(Objects.requireNonNull(getFlutterEngine()).getDartExecutor().getBinaryMessenger(), CHANNEL);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "downloadVideo":
                            new Async<Boolean>().run(() -> {
                                String videoId = call.argument("videoId");
                                String quality = call.argument("quality");
                                String downloadId = call.argument("downloadId");

                                return Downloader.downloadVideo(this, videoId, downloadId, quality, (videoId1, downloadId1, progress) -> {
                                    HashMap<String, Object> args = new HashMap<>();

                                    args.put("videoId", videoId1);
                                    args.put("downloadId", downloadId1);
                                    args.put("progress", progress);

                                    new Async<Void>().run(() -> null, (garbage) -> {
                                        channel.invokeMethod("progress", args);
                                        return null;
                                    });
                                });
                            }, (success) -> {
                                result.success(success);
                                return null;
                            });
                            break;
                        case "getThumbnailUrl":
                            new Async<String>().run(() -> Downloader.getThumbnailUrl(call.argument("videoId")), (String data) -> {
                                if (data != null) {
                                    result.success(data);
                                }else{
                                    result.success(false);
                                }

                                return null;
                            });
                            break;
                        case "showNotification":
                            Integer numPendingDownloads = call.argument("numPendingDownloads");
                            NotificationUtil.ShowPendingDownloadNotification(this, numPendingDownloads == null ? 0 : numPendingDownloads);
                            break;
                        case "someTest":
                            //Integer numPendingDownloads = call.argument("numPendingDownloads");
                            //NotificationUtil.ShowPendingDownloadNotification(this, numPendingDownloads == null ? 0 : numPendingDownloads);
                            BackgroundService.StartBackgroundService(this);

                            break;
                    }
                });
    }
}