package de.aztube.aztube_app;

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

import java.io.*;

public class BackgroundService extends Service {

    public static void StartBackgroundService(Context context){
        Intent bgStartIntent = new Intent(context, BackgroundService.class);
        context.startService(bgStartIntent);
    }

    public static final long DEFAULT_SYNC_INTERVAL = 30 * 1000;
    private static final String settingFilePath = "/app_flutter/settings.json";

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
        if(!started || intent.getBooleanExtra("settingsChanged", false)) {
            init();
            started = true;
        }

        return START_STICKY;
    }

    private void readSettingsFile() {
        try {
            File file = new File(getApplicationInfo().dataDir + settingFilePath);
            FileInputStream fis = new FileInputStream(file);
            BufferedReader reader = new BufferedReader(new InputStreamReader(fis));
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }

            Gson gson = new Gson();

            JsonObject settings = gson.fromJson(sb.toString(), JsonObject.class);
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

        @Override
        public void run() {
            RequestQueue queue = Volley.newRequestQueue(context);

            Request<PollResponse> request = new GsonRequest<>(Request.Method.GET, "http://de2.lucaspape.de:4020/poll/" + deviceToken, PollResponse.class,
                    response -> {
                        if (response.getDownloads() == null || response.getDownloads().size() <= 0) return;
                        DownloadRequest req1 = response.getDownloads().get(0);
                        Log.d("AzTube", req1.getVideoId());
                        if (settingAutoDownload) {
                            NotificationUtil.ShowSomething(context, "New Code", req1.getTitle());
                        } else {
                            //TODO
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
