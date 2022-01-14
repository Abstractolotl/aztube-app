package de.aztube.aztube_app.Services;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;
import androidx.annotation.Nullable;

public class WorkerStarterService extends Service {

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
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
        ServiceUtil.StartWorker(this);
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
