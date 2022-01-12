package de.aztube.aztube_app;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

public class NotificationUtil {

    public final static String NOTIFICATION_CHANNEL_ID = "DOWNLOAD_REQUEST_CHANNEL";


    private static NotificationCompat.Builder buildNotification(Context context, String title, String content) {
        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(content)
                //.setStyle(new NotificationCompat.BigTextStyle().bigText("Long Text"))
                .setSmallIcon(R.drawable.icon_notification)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true);

        return builder;
    }

    private static int pushNotification(Context context, Notification notif){
        SharedPreferences sp  = context.getSharedPreferences("notificationId", Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sp.edit();

        final int notificationID = sp.getInt("LAST_NOTIFICATION_ID", 0) + 1;
        editor.putInt("LAST_NOTIFICATION_ID", notificationID);
        editor.apply();

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.notify(notificationID, notif);

        return notificationID;
    }

    public static int ShowPendingDownloadNotification(Context context, int numPendingDownloads){
        NotificationCompat.Builder builder = buildNotification(context, "Download Request", "You have "+numPendingDownloads+" pending Download Requests");
        return pushNotification(context, builder.build());
    }

    public static int ShowSomething(Context context, String title, String content){
        NotificationCompat.Builder builder = buildNotification(context, title, content);
        return pushNotification(context, builder.build());
    }

    public static void CreateNotificationChannel(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(NotificationUtil.NOTIFICATION_CHANNEL_ID, "Download Requests", NotificationManager.IMPORTANCE_DEFAULT);
            channel.setDescription("Requests to Download Media");
            NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

}
