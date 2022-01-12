package de.aztube.aztube_app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class BootCompletedIntentReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        Intent bgStartIntent = new Intent(context, BackgroundService.class);
        context.startService(bgStartIntent);
    }

}
