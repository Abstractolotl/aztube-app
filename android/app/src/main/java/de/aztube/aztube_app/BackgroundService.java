package de.aztube.aztube_app;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;
import androidx.annotation.Nullable;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;

public class BackgroundService extends Service {

    private Handler mHandler;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        mHandler = new Handler();
        mHandler.post(runnableService);

        return START_STICKY;
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    public static class PollRequest implements Runnable {

        private Context context;

        public PollRequest(Context context) {
            this.context = context;
        }

        @Override
        public void run() {
            RequestQueue queue = Volley.newRequestQueue(context);
            StringRequest stringRequest = new StringRequest(Request.Method.GET, "http://de2.lucaspape.de:4020/api/v1/qr/generate",
                    response -> {
                        Log.d("Yes", "Some Stuff");
                        Log.d("Yes", response);
                    },
                    error -> {
                        Log.d("Yes", error.toString());
                    });
            queue.add(stringRequest);
        }
    }

}
