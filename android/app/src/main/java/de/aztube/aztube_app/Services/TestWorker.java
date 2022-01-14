package de.aztube.aztube_app.Services;

import android.content.Context;
import android.content.Intent;
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
import de.aztube.aztube_app.MainActivity;
import org.jetbrains.annotations.NotNull;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

import static de.aztube.aztube_app.Services.ServiceUtil.*;

public class TestWorker extends Worker {

    private boolean canceled;

    public TestWorker(@NonNull @NotNull Context context, @NonNull @NotNull WorkerParameters workerParams) {
        super(context, workerParams);
    }

    @NonNull
    @NotNull
    @Override
    public Result doWork() {
        Settings settings = readSettings(getApplicationContext());

        for(int i = 0; i < 25; i++) {
            Log.d("AzTube", "Working");
            if(canceled) {
                Log.d("AzTube", "Worker canceled");
                return Result.failure();
            }

            poll(settings);

            try {
                Thread.sleep(30 * 1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        return Result.success();
    }

    private void startDownload(DownloadRequest req, int notifId) {
        AtomicReference<String> url = new AtomicReference<>();
        AtomicReference<Long> lastUpdate = new AtomicReference<>();
        lastUpdate.set(0L);
        new Async<Boolean>().run(() -> {
            url.set(Downloader.downloadVideo(getApplicationContext(), req.getVideoId(), req.getDownloadId(), req.getQuality(), new Downloader.ProgressUpdate() {
                @Override
                public void run(Downloader.Download download) {
                    if(download.progress == 100) {
                        if(notifId != -1) NotificationUtil.ShowDownloadingNotification(getApplicationContext(), "Download complete", req.getTitle(), notifId);
                    } else if (System.currentTimeMillis() - lastUpdate.get() > 1000) {
                        lastUpdate.set(System.currentTimeMillis());
                        if(notifId != -1) NotificationUtil.ShowDownloadingNotification(getApplicationContext(), "Downloading - " + download.progress + "%", req.getTitle(), notifId);
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
                if(notifId != -1) NotificationUtil.ShowSomething(getApplicationContext(), "Error", "Could not save to Cache");
                return null;
            }

            Log.d("AzTube", "Download finished");
            if(canceled) {
                Log.d("AzTube", "Sending Intent");
                Intent intent = new Intent(getApplicationContext(), MainActivity.class);
                intent.putExtra("reloadUI", true);
                intent.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_NEW_TASK);
                getApplicationContext().startActivity(intent);
            }
            return null;
        });
    }

    private void poll(Settings settings) {
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
                        if(settings.isShowNotifications()) NotificationUtil.ShowSomething(getApplicationContext(), "Error", "Could not save to Cache");
                    }

                    if (settings.isSettingAutoDownload()) {
                        for(DownloadRequest req : response.getDownloads()) {
                            int notifId = -1;
                            if(settings.isShowNotifications()) notifId = NotificationUtil.ShowSomething(getApplicationContext(), "Starting Download", req.getTitle());
                            startDownload(req, notifId);
                        }
                    }
                },
                error -> {
                    Log.d("AzTube", error.toString(), error);
                    Log.d("AzTube", "Crashed on Response: " + new String(error.networkResponse.data, StandardCharsets.UTF_8));
                    canceled = true;
                }
        );


        queue.add(request);
    }

    @Override
    public void onStopped() {
        super.onStopped();
        canceled = true;
    }
}