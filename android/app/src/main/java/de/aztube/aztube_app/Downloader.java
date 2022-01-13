package de.aztube.aztube_app;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
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
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class Downloader {

    public static class Download {
        public boolean done;
        public int progress;
        public int downloadId;
        public String videoId;

        Download(boolean done, int progress, int downloadId, String videoId){
            this.done = done;
            this.progress = progress;
            this.downloadId = downloadId;
            this.videoId = videoId;
        }

        HashMap<String, Object> toHashMap(){
            HashMap<String, Object> map = new HashMap<>();

            map.put("done", done);
            map.put("progress", progress);
            map.put("downloadId", downloadId);
            map.put("videoId", videoId);

            return map;
        }
    }

    public interface ProgressUpdate {
        void run(Download download);
    }

    private static final HashMap<Integer, Download> downloads = new HashMap<>();

    public static String downloadVideo(Context context, String videoId, Integer downloadId, String quality, ProgressUpdate progressUpdate){
        VideoInfo videoInfo = Downloader.requestVideoInfo(videoId);

        Format format = null;
        if (quality != null) {
            format = Downloader.getVideoFormat(videoInfo, quality);
        }

        if(format != null){
            return Downloader.downloadVideo(context, format, videoInfo, videoId, downloadId, quality.equals("audio"), progressUpdate);
        }else{
            return null;
        }
    }

    public static String getThumbnailUrl(String videoId){
        VideoInfo videoInfo = Downloader.requestVideoInfo(videoId);
        return Downloader.getThumbnailUrl(videoInfo);
    }

    public static List<HashMap<String, Object>> getActiveDownloads(){
        ArrayList<HashMap<String, Object>> downloadList = new ArrayList<>();

        for(Integer downloadId : downloads.keySet()){
            Download download = downloads.get(downloadId);

            if(download != null && !download.done){
                downloadList.add(download.toHashMap());
            }
        }

        return downloadList;
    }

    public static boolean deleteDownload(Context context, String uri){
        try{
            return context.getContentResolver().delete(Uri.parse(uri), null, null) > 0;
        }catch (SecurityException e){
            return false;
        }
    }

    public static void openDownload(Context context, String uri){
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse(uri));
        context.startActivity(intent);
    }

    public static boolean downloadExists(Context context, String uri){
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(Uri.parse(uri));
            inputStream.close();
            
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    public static void registerProgressUpdate(Integer downloadId, ProgressUpdate progressUpdate){
        ArrayList<ProgressUpdate> progressUpdateArrayList = progressUpdaters.get(downloadId);

        if(progressUpdateArrayList == null){
            progressUpdateArrayList = new ArrayList<>();
        }

        progressUpdateArrayList.add(progressUpdate);
        progressUpdaters.put(downloadId, progressUpdateArrayList);
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

    private static final HashMap<Integer, ArrayList<ProgressUpdate>> progressUpdaters = new HashMap<>();

    private static String downloadVideo(Context context, Format format, VideoInfo videoInfo, String videoId, Integer downloadId, Boolean audio, ProgressUpdate progressUpdate) {
        final Boolean[] success = {false};

        registerProgressUpdate(downloadId, progressUpdate);

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
                    Download download = new Download(false, progress, downloadId, videoId);

                    downloads.put(downloadId, download);

                    ArrayList<ProgressUpdate> progressUpdateArrayList = progressUpdaters.get(downloadId);

                    if(progressUpdateArrayList != null){
                        for(ProgressUpdate progressUpdate : progressUpdateArrayList){
                            progressUpdate.run(download);
                        }
                    }
                }

                @Override
                public void onFinished(Void data) {
                    Download download = new Download(true, 100, downloadId, videoId);
                    downloads.put(downloadId, download);

                    success[0] = true;
                }

                @Override
                public void onError(Throwable throwable) {
                    Download download = new Download(true, -1, downloadId, videoId);
                    downloads.put(downloadId, download);

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

        if(success[0]){
            return uriSaved.toString();
        }else{
            return null;
        }
    }
}
