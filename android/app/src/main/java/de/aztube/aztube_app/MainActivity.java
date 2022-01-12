package de.aztube.aztube_app;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.net.Uri;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;

import androidx.annotation.NonNull;

import androidx.annotation.Nullable;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.YoutubeProgressCallback;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.downloader.request.RequestVideoStreamDownload;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import com.github.kiulian.downloader.model.videos.formats.VideoWithAudioFormat;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    public static final String CHANNEL = "de.aztube.aztube_app/youtube";

    @Override
    protected void onCreate(@Nullable @org.jetbrains.annotations.Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        NotificationUtil.CreateNotificationChannel(this);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "downloadVideo":
                            new Async<Boolean>().run(() -> {
                                VideoInfo videoInfo = requestVideoInfo(call.argument("videoId"));
                                Format format = getVideoFormat(videoInfo, call.argument("quality"));

                                if(format != null){
                                    return downloadVideo(format, videoInfo, call.argument("quality").equals("audio_only"));
                                }else{
                                    return false;
                                }
                            }, (success) -> {
                                result.success(success);
                                return null;
                            });
                            break;
                        case "getThumbnailUrl":
                            new Async<String>().run(() -> {
                                VideoInfo videoInfo = requestVideoInfo(call.argument("videoId"));
                                return getThumbnailUrl(videoInfo);
                            }, (String data) -> {
                                if (data != null) {
                                    result.success(data);
                                }else{
                                    result.success(false);
                                }

                                return null;
                            });
                            break;
                        case "showNotification":
                            Integer numPendingDownloads = call.argument("numPendingDownloads");
                            NotificationUtil.ShowPendingDownloadNotification(this, numPendingDownloads == null ? 0 : numPendingDownloads);
                            break;
                    }
                });
    }

    public VideoInfo requestVideoInfo(String videoId) {
        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        RequestVideoInfo request = new RequestVideoInfo(videoId);

        return youtubeDownloader.getVideoInfo(request).data();
    }

    public String getThumbnailUrl(VideoInfo videoInfo) {
        List<String> thumbnails = videoInfo.details().thumbnails();

        return thumbnails.get(thumbnails.size()-1);
    }

    public Format getVideoFormat(VideoInfo videoInfo, String quality) {
        List<VideoWithAudioFormat> videoFormats = videoInfo.videoWithAudioFormats();
        List<AudioFormat> audioFormats = videoInfo.audioFormats();

        Format format = null;

        if (quality.equals("audio_only")) {
            if (audioFormats.size() > 0) {
                format = audioFormats.get(0);

                for (AudioFormat audioFormat : audioFormats) {
                    if (audioFormat.averageBitrate() > ((AudioFormat) format).averageBitrate()) {
                        format = audioFormat;
                    }
                }
            } else {
                System.out.println("No audio formats available!");
                return null;
            }
        } else {
            for (VideoWithAudioFormat videoFormat : videoFormats) {
                if (videoFormat.qualityLabel().equals(quality)) {
                    format = videoFormat;
                    break;
                }
            }

            if (format == null) {
                System.out.println("Could not find video format!");
                return null;
            }
        }

        return format;
    }

    public boolean downloadVideo(Format format, VideoInfo videoInfo, Boolean audio) {
        final Boolean[] success = {false};

        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        String filename;

        if(audio){
            filename = "video_" + System.currentTimeMillis() + ".mp4";
        }else{
            filename = "audio_" + System.currentTimeMillis() + ".weba";
        }

        ContentValues contentValues = new ContentValues();
        ContentResolver contentResolver = getContentResolver();

        Uri uriSaved;

        if(audio){
            contentValues.put(MediaStore.Audio.Media.TITLE, filename);
            contentValues.put(MediaStore.Audio.Media.DISPLAY_NAME, videoInfo.details().title());
            contentValues.put(MediaStore.Audio.Media.MIME_TYPE, "audio/ogg");
            contentValues.put(MediaStore.Audio.Media.RELATIVE_PATH, "Music/" + "AZTube");
            contentValues.put(MediaStore.Audio.Media.DATE_ADDED, System.currentTimeMillis()/1000);
            contentValues.put(MediaStore.Audio.Media.DATE_TAKEN, System.currentTimeMillis());
            contentValues.put(MediaStore.Audio.Media.IS_PENDING, 1);

            Uri collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
            uriSaved = contentResolver.insert(collection, contentValues);
        }else{
            contentValues.put(MediaStore.Video.Media.TITLE, filename);
            contentValues.put(MediaStore.Video.Media.DISPLAY_NAME, videoInfo.details().title());
            contentValues.put(MediaStore.Video.Media.MIME_TYPE, "video/mp4");
            contentValues.put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/" + "AZTube");
            contentValues.put(MediaStore.Video.Media.DATE_ADDED, System.currentTimeMillis()/1000);
            contentValues.put(MediaStore.Video.Media.DATE_TAKEN, System.currentTimeMillis());
            contentValues.put(MediaStore.Video.Media.IS_PENDING, 1);

            Uri collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
            uriSaved = contentResolver.insert(collection, contentValues);
        }

        ParcelFileDescriptor parcelFileDescriptor;

        try {
            parcelFileDescriptor = getContentResolver().openFileDescriptor(uriSaved, "w");

            FileOutputStream fileOutputStream = new FileOutputStream(parcelFileDescriptor.getFileDescriptor());

            RequestVideoStreamDownload request = new RequestVideoStreamDownload(format, fileOutputStream).callback(new YoutubeProgressCallback<Void>() {
                @Override
                public void onDownloading(int progress) {
                    System.out.println(progress);
                }

                @Override
                public void onFinished(Void data) {
                    success[0] = true;
                }

                @Override
                public void onError(Throwable throwable) {
                    System.out.println("Error downloading video");
                    success[0] = false;
                }
            });

            youtubeDownloader.downloadVideoStream(request).data();

            if(success[0]){
                contentValues.clear();

                if(audio && success[0]){
                    contentValues.put(MediaStore.Audio.Media.IS_PENDING, 0);
                }else{
                    contentValues.put(MediaStore.Video.Media.IS_PENDING, 0);
                }

                getContentResolver().update(uriSaved, contentValues, null, null);
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }

        return success[0];
    }
}