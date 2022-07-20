package de.aztube.aztube_app.Services;

import android.app.*;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import de.aztube.aztube_app.MainActivity;
import de.aztube.aztube_app.R;

public class NotificationUtil {

    public final static String NOTIFICATION_CHANNEL_ID = "DOWNLOAD_REQUEST_CHANNEL";


    private static NotificationCompat.Builder buildNotification(Context context, String title, String content) {
        Intent notificationIntent = new Intent(context, MainActivity.class);
        notificationIntent.setFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
        PendingIntent intent = PendingIntent.getActivity(context, 0, notificationIntent, Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | PendingIntent.FLAG_IMMUTABLE);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setContentTitle(title)
                //.setContentText(content)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(content))
                .setSmallIcon(R.drawable.icon_notification)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setContentIntent(intent)
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

    private static int pushNotification(Context context, Notification notif, int notifId){
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.notify(notifId, notif);
        return notifId;
    }

    public static int ShowPendingDownloadNotification(Context context, int numPendingDownloads){
        NotificationCompat.Builder builder = buildNotification(context, "Download Request",
                "You have " + numPendingDownloads + " pending Download Requests");
        return pushNotification(context, builder.build());
    }

    public static int ShowSomething(Context context, String title, String content){
        NotificationCompat.Builder builder = buildNotification(context, title, content);
        return pushNotification(context, builder.build());
    }

    public static int ShowDownloadingNotification(Context context, String title, String content, int notifId){
        NotificationCompat.Builder builder = buildNotification(context, title, content);

        builder.setProgress(0, 0, false)
        builder.setOnlyAlertOnce(true);

        return pushNotification(context, builder.build(), notifId);
    }

    public static int ShowDownloadingNotification(Context context, String title, String content, int notifId, int progress){
        NotificationCompat.Builder builder = buildNotification(context, title, content);

        if(progress == 100){
            builder.setProgress(0, 0, false)
        }else{
            builder.setProgress(100, progress, false)
        }
        builder.setOnlyAlertOnce(true);

        return pushNotification(context, builder.build(), notifId);
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
