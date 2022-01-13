package de.aztube.aztube_app;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;

import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.FFmpegSession;
import com.arthenica.ffmpegkit.ReturnCode;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.YoutubeProgressCallback;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import com.github.kiulian.downloader.model.videos.formats.VideoFormat;

import java.io.File;
import java.io.FileInputStream;
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

        Download(boolean done, int progress, int downloadId, String videoId) {
            this.done = done;
            this.progress = progress;
            this.downloadId = downloadId;
            this.videoId = videoId;
        }

        HashMap<String, Object> toHashMap() {
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

    public static String downloadVideo(Context context, String videoId, Integer downloadId, String quality, ProgressUpdate progressUpdate) {
        VideoInfo videoInfo = Downloader.requestVideoInfo(videoId);

        List<Format> formats = null;
        if (quality != null) {
            formats = Downloader.getVideoFormats(videoInfo, quality);
        }

        if (formats != null) {
            return Downloader.downloadVideo(context, formats, videoInfo, videoId, downloadId, quality.equals("audio"), progressUpdate);
        } else {
            return null;
        }
    }

    public static String getThumbnailUrl(String videoId) {
        VideoInfo videoInfo = Downloader.requestVideoInfo(videoId);
        return Downloader.getThumbnailUrl(videoInfo);
    }

    public static List<HashMap<String, Object>> getActiveDownloads() {
        ArrayList<HashMap<String, Object>> downloadList = new ArrayList<>();

        for (Integer downloadId : downloads.keySet()) {
            Download download = downloads.get(downloadId);

            if (download != null && !download.done) {
                downloadList.add(download.toHashMap());
            }
        }

        return downloadList;
    }

    public static boolean deleteDownload(Context context, String uri) {
        try {
            return context.getContentResolver().delete(Uri.parse(uri), null, null) > 0;
        } catch (SecurityException e) {
            return false;
        }
    }

    public static void openDownload(Context context, String uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse(uri));
        context.startActivity(intent);
    }

    public static boolean downloadExists(Context context, String uri) {
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(Uri.parse(uri));
            inputStream.close();

            return true;
        } catch (IOException e) {
            return false;
        }
    }

    public static void registerProgressUpdate(Integer downloadId, ProgressUpdate progressUpdate) {
        ArrayList<ProgressUpdate> progressUpdateArrayList = progressUpdaters.get(downloadId);

        if (progressUpdateArrayList == null) {
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

        return thumbnails.get(thumbnails.size() - 1);
    }

    private static List<Format> getVideoFormats(VideoInfo videoInfo, String quality) {
        List<VideoFormat> videoFormats = videoInfo.videoFormats();
        List<AudioFormat> audioFormats = videoInfo.audioFormats();

        ArrayList<Format> formats = new ArrayList<>();

        AudioFormat audioFormat;

        if (audioFormats.size() > 0) {
            audioFormat = audioFormats.get(0);

            for (AudioFormat bestAudioFormat : audioFormats) {
                if (bestAudioFormat.averageBitrate() > audioFormat.averageBitrate()) {
                    audioFormat = bestAudioFormat;
                }
            }

            formats.add(audioFormat);
        } else {
            System.out.println("No audio formats available!");
            return null;
        }

        if (!quality.equals("audio")) {
            Format videoFormat = null;

            for (VideoFormat bestVideoFormat : videoFormats) {
                if (bestVideoFormat.qualityLabel().equals(quality)) {
                    videoFormat = bestVideoFormat;
                    break;
                }
            }

            if (videoFormat != null) {
                formats.add(videoFormat);
            } else {
                System.out.println("Video format not found");
                return null;
            }
        }

        return formats;
    }

    private static final HashMap<Integer, ArrayList<ProgressUpdate>> progressUpdaters = new HashMap<>();

    private static String downloadVideo(Context context, List<Format> formats, VideoInfo videoInfo, String videoId, Integer downloadId, Boolean audio, ProgressUpdate progressUpdate) {
        boolean success = false;

        String thumbnail = context.getExternalFilesDir(Environment.DIRECTORY_MOVIES) + "/thumbnail_" + downloadId + ".jpg";

        try {
            InputStream input = new java.net.URL(getThumbnailUrl(videoId)).openStream();
            Bitmap bitmap = BitmapFactory.decodeStream(input);

            FileOutputStream out = new FileOutputStream(thumbnail);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out);
            out.close();
        } catch (IOException e) {
            e.printStackTrace();

            thumbnail = null;
        }

        ArrayList<String> files = new ArrayList<>();

        double startProgress = 0;

        for (Format format : formats) {
            double progressFactor = 0.9;

            boolean isAudio = format instanceof AudioFormat;

            if (isAudio && formats.size() > 1) {
                progressFactor = 0.2;
            } else if (formats.size() > 1) {
                progressFactor = 0.7;
            }

            String file = downloadFormat(context, format, videoId, downloadId, isAudio, progressUpdate, startProgress, progressFactor);

            if (file != null) {
                files.add(file);
            } else {
                System.out.println("Part of download failed.");
                return null;
            }

            startProgress += progressFactor * 100;
        }

        String filename = context.getExternalFilesDir(Environment.DIRECTORY_MOVIES) + "/video_combined_" + downloadId + ".mkv";

        if (files.size() > 1) {
            System.out.println("Combining video and audio");

            FFmpegSession session;

            if(thumbnail != null){
                session = FFmpegKit.execute("-y -i " + files.get(0) + " -i " + files.get(1) + " -c:v copy -c:a aac -attach " + thumbnail + " -metadata:s:t mimetype=image/jpeg " + filename);
            }else{
                session = FFmpegKit.execute("-y -i " + files.get(0) + " -i " + files.get(1) + " -c:v copy -c:a aac " + filename);
            }

            if (ReturnCode.isSuccess(session.getReturnCode())) {
                Download download = new Download(false, 100, downloadId, videoId);

                new Async<Void>().runOnMain(() -> {
                    downloads.put(downloadId, download);

                    ArrayList<ProgressUpdate> progressUpdateArrayList = progressUpdaters.get(downloadId);

                    if (progressUpdateArrayList != null) {
                        for (ProgressUpdate runProgressUpdate : progressUpdateArrayList) {
                            runProgressUpdate.run(download);
                        }
                    }
                    return null;
                });

                System.out.println("Video and audio combined.");

                for (String file : files) {
                    boolean result = new File(file).delete();

                    if (!result) {
                        System.out.println("Failed to delete part file");
                    }
                }
            } else {
                System.out.println("Failed to combine video and audio.");

                return null;
            }
        } else {
            if(thumbnail != null){
                filename = new StringBuilder(files.get(0)).insert(files.get(0).lastIndexOf("/")+1, "thumbnail-").toString();

                FFmpegSession session;

                if(audio){
                    filename += ".mp3";
                    session = FFmpegKit.execute("-y -i " + files.get(0) + " -i " + thumbnail + " -map 0:0 -map 1:0 -c:a libmp3lame -id3v2_version 3 -metadata:s:v title=\"Album cover\" -metadata:s:v comment=\"Cover (front)\" " + filename);
                }else{
                    session = FFmpegKit.execute("-y -i " + files.get(0) + " -c:v copy -c:a aac -attach " + thumbnail + " -metadata:s:t mimetype=image/jpeg " + filename);
                }

                if (ReturnCode.isSuccess(session.getReturnCode())) {
                    Download download = new Download(false, 100, downloadId, videoId);

                    new Async<Void>().runOnMain(() -> {
                        downloads.put(downloadId, download);

                        ArrayList<ProgressUpdate> progressUpdateArrayList = progressUpdaters.get(downloadId);

                        if (progressUpdateArrayList != null) {
                            for (ProgressUpdate runProgressUpdate : progressUpdateArrayList) {
                                runProgressUpdate.run(download);
                            }
                        }
                        return null;
                    });

                    System.out.println("Added thumbnail.");

                    for (String file : files) {
                        boolean result = new File(file).delete();

                        if (!result) {
                            System.out.println("Failed to delete part file");
                        }
                    }
                } else {
                    System.out.println("Failed to add thumbnail");

                    return null;
                }
            }else{
                filename = files.get(0);
            }
        }

        ContentValues contentValues = new ContentValues();
        ContentResolver contentResolver = context.getContentResolver();

        Uri uriSaved;

        if (audio) {
            contentValues.put(MediaStore.Audio.Media.TITLE, filename);
            contentValues.put(MediaStore.Audio.Media.DISPLAY_NAME, videoInfo.details().title());
            contentValues.put(MediaStore.Audio.Media.MIME_TYPE, "audio/mpeg");
            contentValues.put(MediaStore.Audio.Media.RELATIVE_PATH, "Music/" + "AZTube");
            contentValues.put(MediaStore.Audio.Media.DATE_ADDED, System.currentTimeMillis() / 1000);
            contentValues.put(MediaStore.Audio.Media.DATE_TAKEN, System.currentTimeMillis());
            contentValues.put(MediaStore.Audio.Media.IS_PENDING, 1);

            Uri collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
            uriSaved = contentResolver.insert(collection, contentValues);
        } else {
            contentValues.put(MediaStore.Video.Media.TITLE, filename);
            contentValues.put(MediaStore.Video.Media.DISPLAY_NAME, videoInfo.details().title());
            contentValues.put(MediaStore.Video.Media.MIME_TYPE, "video/x-matroska");
            contentValues.put(MediaStore.Video.Media.RELATIVE_PATH, "Movies/" + "AZTube");
            contentValues.put(MediaStore.Video.Media.DATE_ADDED, System.currentTimeMillis() / 1000);
            contentValues.put(MediaStore.Video.Media.DATE_TAKEN, System.currentTimeMillis());
            contentValues.put(MediaStore.Video.Media.IS_PENDING, 1);

            Uri collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
            uriSaved = contentResolver.insert(collection, contentValues);
        }

        ParcelFileDescriptor parcelFileDescriptor;

        try {
            parcelFileDescriptor = context.getContentResolver().openFileDescriptor(uriSaved, "w");

            FileOutputStream fileOutputStream = new FileOutputStream(parcelFileDescriptor.getFileDescriptor());
            FileInputStream fileInputStream = new FileInputStream(filename);

            byte[] buffer = new byte[1024];
            int length;

            try {
                while ((length = fileInputStream.read(buffer)) > 0) {
                    fileOutputStream.write(buffer, 0, length);
                }

                success = true;
            } catch (IOException e) {
                e.printStackTrace();
                success = false;
            } finally {
                try {
                    fileInputStream.close();
                    fileOutputStream.close();
                } catch (IOException e) {
                    e.printStackTrace();
                    success = false;
                }
            }

            if (!new File(filename).delete()) {
                success = false;
            }

            if (success) {
                contentValues.clear();

                if (audio) {
                    contentValues.put(MediaStore.Audio.Media.IS_PENDING, 0);
                } else {
                    contentValues.put(MediaStore.Video.Media.IS_PENDING, 0);
                }
                context.getContentResolver().update(uriSaved, contentValues, null, null);
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }

        if (success) {
            return uriSaved.toString();
        } else {
            return null;
        }
    }

    private static String downloadFormat(Context context, Format format, String videoId, Integer downloadId, Boolean audio, ProgressUpdate progressUpdate, Double progressStart, Double progressFactor) {
        final Boolean[] success = {false};

        new Async<Void>().runOnMain(() -> {
            registerProgressUpdate(downloadId, progressUpdate);

            return null;
        });

        String filename;

        if (audio) {
            filename = "audio_" + downloadId;
        } else {
            filename = "video_" + downloadId;
        }

        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        RequestVideoFileDownload videoFileDownload = new RequestVideoFileDownload(format).callback(new YoutubeProgressCallback<File>() {
            @Override
            public void onDownloading(int progress) {
                Download download = new Download(false, (int) (progressStart + (progress * progressFactor)), downloadId, videoId);

                new Async<Void>().runOnMain(() -> {
                    downloads.put(downloadId, download);

                    ArrayList<ProgressUpdate> progressUpdateArrayList = progressUpdaters.get(downloadId);

                    if (progressUpdateArrayList != null) {
                        for (ProgressUpdate progressUpdate : progressUpdateArrayList) {
                            progressUpdate.run(download);
                        }
                    }

                    return null;
                });
            }

            @Override
            public void onFinished(File data) {
                Download download = new Download(true, (int) (progressStart + (100 * progressFactor)), downloadId, videoId);

                new Async<Void>().runOnMain(() -> {
                    downloads.put(downloadId, download);

                    return null;
                });

                success[0] = true;
            }

            @Override
            public void onError(Throwable throwable) {
                Download download = new Download(true, -1, downloadId, videoId);

                new Async<Void>().runOnMain(() -> {
                    downloads.put(downloadId, download);

                    return null;
                });

                System.out.println("Error downloading video");
                success[0] = false;
            }
        }).saveTo(context.getExternalFilesDir(Environment.DIRECTORY_MOVIES)).renameTo(filename);

        File data = youtubeDownloader.downloadVideoFile(videoFileDownload).data();

        if (success[0]) {
            return data.getAbsolutePath();
        } else {
            return null;
        }
    }
}
