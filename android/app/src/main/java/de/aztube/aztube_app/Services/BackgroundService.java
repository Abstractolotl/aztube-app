package de.aztube.aztube_app.Services;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.Nullable;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import de.aztube.aztube_app.*;
import de.aztube.aztube_app.Communication.*;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

public class BackgroundService extends Service {

    public static void StartBackgroundService(Context context){
        Intent bgStartIntent = new Intent(context, BackgroundService.class);
        context.startService(bgStartIntent);
    }

    private static CachedDownload cachedFromReqeust(DownloadRequest req){
        return new CachedDownload(req.getDownloadId(), req.getVideoId(), req.getQuality(), req.getTitle(), req.getAuthor(), false, "", "");
    }

    public static final long DEFAULT_SYNC_INTERVAL = 30 * 1000;

    private Handler handler;
    private boolean started;

    private boolean settingAutoDownload;
    private String deviceToken;

    private void init() {
        readSettingsFile();
        if(deviceToken != null && !deviceToken.trim().equals("")) {
            handler = new Handler(Looper.getMainLooper());
            handler.post(new PollRequestRunner(this, handler));
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        boolean settingsChanged = intent.getBooleanExtra("settingsChanged", false);
        if(settingsChanged) {
            readSettingsFile();
        }
        if(!started) {
            init();
            started = true;
        }

        return START_STICKY;
    }

    @Override
    public void onCreate() {
        Log.d("AzTube", "Service Created");
        super.onCreate();
    }

    @Override
    public void onDestroy() {
        Log.d("AzTube", "Service Destroyed");
        super.onDestroy();
    }

    private Cache readCache() {
        try {
            String file = readFile("downloads.json");
            Gson gson = new Gson();
            return gson.fromJson(file, Cache.class);
        } catch (IOException e) {
            return new Cache();
        }

    }

    private void saveCache(Cache cache) throws IOException {
        Gson gson = new Gson();
        String jsonString = gson.toJson(cache);

        File file = new File(getApplicationInfo().dataDir + "/app_flutter/downloads.json");
        FileOutputStream fout = new FileOutputStream(file);
        fout.write(jsonString.getBytes(StandardCharsets.UTF_8));
    }

    private String readFile(String filename) throws IOException {
        File file = new File(getApplicationInfo().dataDir + "/app_flutter/" + filename);
        FileInputStream fis = new FileInputStream(file);
        BufferedReader reader = new BufferedReader(new InputStreamReader(fis));
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line);
        }

        return sb.toString();
    }

    private void readSettingsFile() {
        try {
            String file = readFile("settings.json");
            Gson gson = new Gson();

            JsonObject settings = gson.fromJson(file, JsonObject.class);
            JsonElement json;
            if((json = settings.get("background")) != null) settingAutoDownload = json.getAsBoolean();
            if((json = settings.get("device")) != null) deviceToken = json.getAsString();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private class PollRequestRunner implements Runnable {
        private Context context;
        private Handler handler;

        public PollRequestRunner(Context context, Handler handler) {
            this.context = context;
            this.handler = handler;
        }

        private void restartService() {
            handler.postDelayed(new PollRequestRunner(context, handler), DEFAULT_SYNC_INTERVAL);
        }

        private void startDownload(DownloadRequest req, int notifId) {
            AtomicReference<String> url = new AtomicReference<>();
            new Async<Boolean>().run(() -> {
                url.set(Downloader.downloadVideo(context, req.getVideoId(), req.getDownloadId(), req.getQuality(), new Downloader.ProgressUpdate() {
                    @Override
                    public void run(Downloader.Download download) {
                        if (download.progress % 10 == 0) {
                            NotificationUtil.ShowSomething(context, "Downloading", req.getTitle() + " - " + download.progress + "%", notifId);
                        }
                    }
                }));

                return true;
            }, (success) -> {
                Cache cache = readCache();
                CachedDownload cachedDownload = cache.getQueue().stream()
                        .filter((e) -> e.getDownloadId() == req.getDownloadId())
                        .findFirst()
                        .orElse(cachedFromReqeust(req));
                cache.getQueue().remove(cachedDownload);

                cachedDownload.setDownloaded(true);
                cachedDownload.setSavedTo(url.get());
                cache.getDownloaded().add(cachedDownload);
                try {
                    saveCache(cache);
                } catch (IOException e) {
                    NotificationUtil.ShowSomething(context, "Error", "Could not save to Cache");
                }
                return null;
            });
        }

        @Override
        public void run() {
            //NotificationUtil.ShowSomething(context, "Polling", "");
            RequestQueue queue = Volley.newRequestQueue(context);

            Request<PollResponse> request = new GsonRequest<>(Request.Method.GET, "http://de2.lucaspape.de:4020/poll/" + deviceToken, PollResponse.class,
                    response -> {
                        if (response.getDownloads() == null || response.getDownloads().size() <= 0) {
                            restartService();
                            return;
                        }

                        Cache cache = readCache();
                        for(DownloadRequest req : response.getDownloads()) {
                            cache.getQueue().add(cachedFromReqeust(req));
                        }
                        try {
                            saveCache(cache);
                        } catch (IOException e) {
                            NotificationUtil.ShowSomething(context, "Error", "Could not save to Cache");
                        }

                        if (settingAutoDownload) {
                            for(DownloadRequest req : response.getDownloads()) {
                                int notifId = NotificationUtil.ShowSomething(context, "Starting Download", req.getTitle());
                                startDownload(req, notifId);
                            }
                        }
                        restartService();
                    },
                    error -> {
                        Log.d("AzTube", error.toString(), error);
                        NotificationUtil.ShowSomething(context, "Error", "Something went Wrong :c");
                    }
            );

            queue.add(request);
        }
    }

}
