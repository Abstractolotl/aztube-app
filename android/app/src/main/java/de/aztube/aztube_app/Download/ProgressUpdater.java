package de.aztube.aztube_app.Download;

import android.util.Log;
import de.aztube.aztube_app.Async;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class ProgressUpdater {

    public static class ProgressUpdate{
        public boolean done;
        public int progress;
        public int downloadId;
        public String videoId;

        public ProgressUpdate(boolean done, int progress, int downloadId, String videoId) {
            this.done = done;
            this.progress = progress;
            this.downloadId = downloadId;
            this.videoId = videoId;
        }

        public HashMap<String, Object> toHashMap() {
            HashMap<String, Object> map = new HashMap<>();

            if(progress > 100){
                progress = 100;
            }

            map.put("done", done);
            map.put("progress", progress);
            map.put("downloadId", downloadId);
            map.put("videoId", videoId);

            return map;
        }
    }

    public interface ProgressUpdateCallback {
        void onUpdate(ProgressUpdate update);
    }

    private final static HashMap<Integer, ArrayList<ProgressUpdateCallback>> callbackRegister = new HashMap<>();
    private final static HashMap<Integer, ProgressUpdate> latestUpdates = new HashMap<>();

    public static List<Map<String, Object>> getActiveDownloads(){
        return latestUpdates.values().stream().filter(update -> !update.done).map(ProgressUpdate::toHashMap).collect(Collectors.toList());
    }

    public static void registerProgressUpdateCallback(int downloadId, ProgressUpdateCallback callback) {
        if(callback == null)
            return;

        new Async<Void>().runOnMain(() -> {
            ArrayList<ProgressUpdateCallback> progressUpdateArrayList = callbackRegister.computeIfAbsent(downloadId, k -> new ArrayList<>());
            progressUpdateArrayList.add(callback);
            return null;
        });
    }

    public static void unregisterAllCallbacks(int downloadId) {
        callbackRegister.remove(downloadId);
        latestUpdates.remove(downloadId);
    }

    public static void publishUpdate(int downloadId, ProgressUpdate update) {
        new Async<Void>().runOnMain(() -> {
            latestUpdates.put(downloadId, update);

            ArrayList<ProgressUpdateCallback> callbacks = callbackRegister.get(downloadId);
            if(callbacks == null) return null;

            for(ProgressUpdateCallback callback : callbacks) {
                callback.onUpdate(update);
            }
            return null;
        });
    }

}
