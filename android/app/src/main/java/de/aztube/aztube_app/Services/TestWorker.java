package de.aztube.aztube_app.Services;

import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.Volley;
import de.aztube.aztube_app.Async;
import de.aztube.aztube_app.Communication.*;
import de.aztube.aztube_app.Downloader;
import org.jetbrains.annotations.NotNull;

import java.io.*;
import java.util.concurrent.atomic.AtomicReference;

import static de.aztube.aztube_app.Services.ServiceUtil.*;

public class TestWorker extends Worker {

    private boolean canceled;

    public TestWorker(@NonNull @NotNull Context context, @NonNull @NotNull WorkerParameters workerParams) {
        super(context, workerParams);
    }

    private void startDownload(DownloadRequest req, int notifId) {
        AtomicReference<String> url = new AtomicReference<>();
        new Async<Boolean>().run(() -> {
            url.set(Downloader.downloadVideo(getApplicationContext(), req.getVideoId(), req.getDownloadId(), req.getQuality(), new Downloader.ProgressUpdate() {
                @Override
                public void run(Downloader.Download download) {
                    if(download.progress == 100) {
                        NotificationUtil.ShowDownloadingNotification(getApplicationContext(), "Download complete", req.getTitle(), notifId);
                    } else if (download.progress % 5 == 0) {
                        NotificationUtil.ShowDownloadingNotification(getApplicationContext(), "Downloading - " + download.progress + "%", req.getTitle(), notifId);
                    }
                }
            }));

            return true;
        }, (success) -> {
            Cache cache = readCache(getApplicationContext());
            CachedDownload cachedDownload = cache.getQueue().stream()
                    .filter((e) -> e.getDownloadId() == req.getDownloadId())
                    .findFirst()
                    .orElse(cachedFromReqeust(req));
            cache.getQueue().remove(cachedDownload);

            cachedDownload.setDownloaded(true);
            cachedDownload.setSavedTo(url.get());
            cache.getDownloaded().add(cachedDownload);
            try {
                saveCache(getApplicationContext(), cache);
            } catch (IOException e) {
                NotificationUtil.ShowSomething(getApplicationContext(), "Error", "Could not save to Cache");
            }
            return null;
        });
    }

    private void poll() {
        NotificationUtil.ShowSomething(getApplicationContext(), "Polling", "");
        Settings settings = readSettings(getApplicationContext());
        if(settings.getDeviceToken() != null && settings.getDeviceToken().trim().equals("")){
            return;
        }

        RequestQueue queue = Volley.newRequestQueue(getApplicationContext());
        Request<PollResponse> request = new GsonRequest<>(Request.Method.GET, "http://de2.lucaspape.de:4020/poll/" + settings.getDeviceToken(), PollResponse.class,
                response -> {
                    if (response.getDownloads() == null || response.getDownloads().size() <= 0) {
                        return;
                    }

                    Cache cache = readCache(getApplicationContext());
                    for(DownloadRequest req : response.getDownloads()) {
                        cache.getQueue().add(cachedFromReqeust(req));
                    }
                    try {
                        saveCache(getApplicationContext(), cache);
                    } catch (IOException e) {
                        NotificationUtil.ShowSomething(getApplicationContext(), "Error", "Could not save to Cache");
                    }

                    if (settings.isSettingAutoDownload()) {
                        for(DownloadRequest req : response.getDownloads()) {
                            int notifId = NotificationUtil.ShowSomething(getApplicationContext(), "Starting Download", req.getTitle());
                            startDownload(req, notifId);
                        }
                    }
                },
                error -> {
                    Log.d("AzTube", error.toString(), error);
                    canceled = true;
                }
        );


        queue.add(request);
    }

    @NonNull
    @NotNull
    @Override
    public Result doWork() {
        NotificationUtil.ShowSomething(getApplicationContext(), "Working", "");

        for(int i = 0; i < 30; i++) {
            if(canceled) return Result.failure();

            poll();

            try {
                Thread.sleep(30 * 1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        return Result.success();
    }

    @Override
    public void onStopped() {
        super.onStopped();
        canceled = true;
    }
}