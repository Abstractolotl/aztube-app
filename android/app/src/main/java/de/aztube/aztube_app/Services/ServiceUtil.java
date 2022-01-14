package de.aztube.aztube_app.Services;

import android.content.Context;
import android.content.Intent;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;
import com.google.gson.Gson;
import de.aztube.aztube_app.Communication.Cache;
import de.aztube.aztube_app.Communication.CachedDownload;
import de.aztube.aztube_app.Communication.DownloadRequest;
import de.aztube.aztube_app.Communication.Settings;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;

public class ServiceUtil {

    public static void StartWorker(Context context) {
        WorkManager wm = WorkManager.getInstance(context);
        PeriodicWorkRequest.Builder builder = new PeriodicWorkRequest.Builder(TestWorker.class, 15, TimeUnit.MINUTES);
        wm.enqueueUniquePeriodicWork("downloadPoll", ExistingPeriodicWorkPolicy.REPLACE, builder.build());
    }

    public static void StartBackgroundService(Context context){
        Intent intent = new Intent(context, WorkerStarterService.class);
        context.startService(intent);
    }

    /*
    public static void StartBackgroundService(Context context, long delay){
        WorkManager wm = WorkManager.getInstance(context);
        PeriodicWorkRequest.Builder builder = new PeriodicWorkRequest.Builder(TestWorker.class, 15, TimeUnit.MINUTES);
        builder.setInitialDelay(delay, TimeUnit.MINUTES);
        wm.enqueueUniquePeriodicWork("downloadPoll", ExistingPeriodicWorkPolicy.REPLACE, builder.build());
    }
    */

    public static void StopWorker(Context context){
        WorkManager wm = WorkManager.getInstance(context);
        wm.cancelUniqueWork("downloadPoll");
    }

    public static CachedDownload cachedFromReqeust(DownloadRequest req){
        return new CachedDownload(req.getDownloadId(), req.getVideoId(), req.getQuality(), req.getTitle(), req.getAuthor(), false, "", "");
    }

    public static String readFile(Context context, String filename) throws IOException {
        File file = new File(context.getApplicationInfo().dataDir + "/app_flutter/" + filename);
        FileInputStream fis = new FileInputStream(file);
        BufferedReader reader = new BufferedReader(new InputStreamReader(fis));
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line);
        }

        return sb.toString();
    }

    public static Settings readSettings(Context context) {
        try {
            String file = readFile(context,"settings.json");
            Gson gson = new Gson();
            return gson.fromJson(file, Settings.class);
        } catch (IOException e) {
            return new Settings();
        }
    }


    public static Cache readCache(Context context) {
        try {
            String file = readFile(context,"downloads.json");
            Gson gson = new Gson();
            return gson.fromJson(file, Cache.class);
        } catch (IOException e) {
            return new Cache();
        }

    }

    public static void saveCache(Context context, Cache cache) throws IOException {
        Gson gson = new Gson();
        String jsonString = gson.toJson(cache);

        File file = new File(context.getApplicationInfo().dataDir + "/app_flutter/downloads.json");
        FileOutputStream fout = new FileOutputStream(file);
        fout.write(jsonString.getBytes(StandardCharsets.UTF_8));
    }

}
