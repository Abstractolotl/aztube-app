package de.aztube.aztube_app;

import android.content.Intent;
import android.os.Bundle;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Objects;
import java.util.logging.Logger;

import de.aztube.aztube_app.Download.DownloadUtil;
import de.aztube.aztube_app.Download.ProgressUpdater;
import de.aztube.aztube_app.Download.VideoDownloader;
import de.aztube.aztube_app.Services.NotificationUtil;
import de.aztube.aztube_app.Services.ServiceUtil;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import org.jetbrains.annotations.NotNull;

public class MainActivity extends FlutterActivity {

    public static final String CHANNEL = "de.aztube.aztube_app/youtube";
    MethodChannel channel;

    @Override
    protected void onNewIntent(@NonNull @NotNull Intent intent) {
        super.onNewIntent(intent);
        if(channel != null && intent.getBooleanExtra("reloadUI", false)) {
            channel.invokeMethod("reload", null);
        }
    }

    @Override
    protected void onCreate(@Nullable @org.jetbrains.annotations.Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        NotificationUtil.CreateNotificationChannel(this);


        channel = new MethodChannel(Objects.requireNonNull(getFlutterEngine()).getDartExecutor().getBinaryMessenger(), CHANNEL);
    }

    @Override
    protected void onStart() {
        super.onStart();
        ServiceUtil.StopWorker(this);
        ServiceUtil.StartBackgroundService(this);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "downloadVideo":
                            new Async<String>().run(() -> {
                                String videoId = call.argument("videoId");
                                String quality = call.argument("quality");
                                Integer downloadId = call.argument("downloadId");
                                String title = call.argument("title");
                                String author = call.argument("author");

                                Integer notifId = NotificationUtil.ShowSomething(getApplicationContext(), "Starting Download", title);

                                if(downloadId == null) return null;
                                return new VideoDownloader(this, videoId, downloadId, title, author, quality)
                                        .startDownload((update -> {
                                            if(update.done) {
                                                if(notifId != -1)
                                                    NotificationUtil.ShowDownloadingNotification(getApplicationContext(), "Download complete", title, notifId);
                                            } else {
                                                if(notifId != -1)
                                                    NotificationUtil.ShowDownloadingNotification(getApplicationContext(), "Downloading", title, notifId, update.progress);
                                            }
                                            channel.invokeMethod("progress", update.toHashMap());
                                        }));
                            }, (uri) -> {
                                if (uri != null) {
                                    result.success(uri);
                                    return null;
                                }

                                result.success(false);
                                return null;
                            });
                            break;
                        case "getThumbnailUrl":
                            new Async<String>().run(() -> DownloadUtil.getThumbnailUrl(call.argument("videoId")), (String data) -> {
                                if (data != null) {
                                    result.success(data);
                                    return null;
                                }

                                result.success(false);
                                return null;
                            });
                            break;
                        case "getActiveDownloads":
                            result.success(ProgressUpdater.getActiveDownloads());
                            break;
                        case "openDownload":
                            DownloadUtil.openFile(this, call.argument("uri"));
                            result.success(true);
                            break;
                        case "deleteDownload":
                            result.success(DownloadUtil.deleteFile(this, call.argument("uri")));
                            break;
                        case "downloadExists":
                            result.success(DownloadUtil.fileExists(this, call.argument("uri")));
                            break;
                        case "registerDownloadProgressUpdate":
                            Integer downloadId = call.argument("downloadId");
                            if(downloadId == null) return;
                            ProgressUpdater.registerProgressUpdateCallback(downloadId, (download) -> channel.invokeMethod("progress", download.toHashMap()));
                            break;
                    }
                });
    }
}