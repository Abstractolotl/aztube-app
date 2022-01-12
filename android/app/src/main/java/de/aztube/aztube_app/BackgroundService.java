package de.aztube.aztube_app;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Environment;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.Nullable;
import com.alibaba.fastjson.JSON;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;
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

    private void init() {
        //handler = new Handler(Looper.getMainLooper());
        //handler.post(new PollRequest(this, handler));

        readSettingsFile();
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
            settingAutoDownload = settings.get("background").getAsBoolean();

            //NotificationUtil.ShowSomething(this, "Settings", sb.toString());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if(!started) {
            init();
            started = true;
        }

        return START_STICKY;
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private class PollRequest implements Runnable {

        private Context context;
        private Handler handler;

        public PollRequest(Context context, Handler handler) {
            this.context = context;
            this.handler = handler;
        }

        private void restartService() {
            handler.postDelayed(new PollRequest(context, handler), DEFAULT_SYNC_INTERVAL);
        }

        @Override
        public void run() {
            RequestQueue queue = Volley.newRequestQueue(context);
            StringRequest stringRequest = new StringRequest(Request.Method.GET, "http://de2.lucaspape.de:4020/generate",
                    response -> {
                        Log.d("AzTube", response);
                        if(settingAutoDownload) {
                            NotificationUtil.ShowSomething(context, "New Code", response);
                        } else {
                            //TODO
                        }
                        restartService();
                    },
                    error -> {
                        Log.d("AzTube", error.toString());
                        NotificationUtil.ShowSomething(context, "Error", "Something went Wrong :c");
                    });
            queue.add(stringRequest);
        }
    }

}
