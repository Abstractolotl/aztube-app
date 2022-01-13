package de.aztube.aztube_app;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;

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


public class Downloader {

    public interface ProgressUpdate {
        void run(String videoId, int downloadId, int progress);
    }

    public static boolean downloadVideo(Context context, String videoId, int downloadId, String quality, ProgressUpdate progressUpdate){
        VideoInfo videoInfo = Downloader.requestVideoInfo(videoId);

        Format format = null;
        if (quality != null) {
            format = Downloader.getVideoFormat(videoInfo, quality);
        }

        if(format != null){
            return Downloader.downloadVideo(context, format, videoInfo, videoId, downloadId, quality.equals("audio"), progressUpdate);
        }else{
            return false;
        }
    }

    public static String getThumbnailUrl(String videoId){
        VideoInfo videoInfo = Downloader.requestVideoInfo(videoId);
        return Downloader.getThumbnailUrl(videoInfo);
    }

    private static VideoInfo requestVideoInfo(String videoId) {
        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        RequestVideoInfo request = new RequestVideoInfo(videoId);

        return youtubeDownloader.getVideoInfo(request).data();
    }

    private static String getThumbnailUrl(VideoInfo videoInfo) {
        List<String> thumbnails = videoInfo.details().thumbnails();

        return thumbnails.get(thumbnails.size()-1);
    }

    private static Format getVideoFormat(VideoInfo videoInfo, String quality) {
        List<VideoWithAudioFormat> videoFormats = videoInfo.videoWithAudioFormats();
        List<AudioFormat> audioFormats = videoInfo.audioFormats();

        Format format = null;

        if (quality.equals("audio")) {
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

    private static boolean downloadVideo(Context context, Format format, VideoInfo videoInfo, String videoId, int downloadId, Boolean audio, ProgressUpdate progressUpdate) {
        final Boolean[] success = {false};

        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        String filename;

        if(audio){
            filename = "video_" + downloadId + ".mp4";
        }else{
            filename = "audio_" + downloadId + ".weba";
        }

        ContentValues contentValues = new ContentValues();
        ContentResolver contentResolver = context.getContentResolver();

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
            parcelFileDescriptor = context.getContentResolver().openFileDescriptor(uriSaved, "w");

            FileOutputStream fileOutputStream = new FileOutputStream(parcelFileDescriptor.getFileDescriptor());

            RequestVideoStreamDownload request = new RequestVideoStreamDownload(format, fileOutputStream).callback(new YoutubeProgressCallback<Void>() {
                @Override
                public void onDownloading(int progress) {
                    progressUpdate.run(videoId, downloadId, progress);
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

                if(audio){
                    contentValues.put(MediaStore.Audio.Media.IS_PENDING, 0);
                }else{
                    contentValues.put(MediaStore.Video.Media.IS_PENDING, 0);
                }

                context.getContentResolver().update(uriSaved, contentValues, null, null);
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }

        return success[0];
    }
}
