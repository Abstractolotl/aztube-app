package de.aztube.aztube_app.Services.Download;

import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.YoutubeProgressCallback;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import de.aztube.aztube_app.DownloadUtil;
import de.aztube.aztube_app.Downloader;

import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class VideoDownloader {

    private Context context;

    private final String videoId;
    private final int downloadId;

    private final String title;
    private final String author;
    private final String quality;

    private int totalProgress = 100;
    private int currentProgress = 0;
    private ProgressUpdater.ProgressUpdateCallback progressCallback;

    public VideoDownloader(Context context, String videoId, int downloadId, String title, String author, String quality) {
        this.context = context;
        this.videoId = videoId;
        this.downloadId = downloadId;
        this.title = title;
        this.author = author;
        this.quality = quality;
    }

    public String startDownload(ProgressUpdater.ProgressUpdateCallback progressCallback) {
        this.progressCallback = progressCallback;
        VideoInfo videoInfo = DownloadUtil.requestVideoInfo(videoId);
        List<Format> formats = DownloadUtil.pickVideoFormat(videoInfo, quality);

        String thumbnailoLcation = DownloadUtil.downloadThumbnail(context, videoId, downloadId);
        List<String> downloadedFiles = downloadFormats(formats);

        if(downloadedFiles.size() == 1) {
            ContentValues contentValues = new ContentValues();
            contentValues.put(MediaStore.Audio.Media.TITLE, downloadedFiles.get(0));
            contentValues.put(MediaStore.Audio.Media.DISPLAY_NAME, videoInfo.details().title());
            contentValues.put(MediaStore.Audio.Media.MIME_TYPE, getMIMEType(downloadedFiles.get(0)));
            contentValues.put(MediaStore.Audio.Media.RELATIVE_PATH, "Music/" + author);
            contentValues.put(MediaStore.Audio.Media.DATE_ADDED, System.currentTimeMillis() / 1000);
            contentValues.put(MediaStore.Audio.Media.DATE_TAKEN, System.currentTimeMillis());
            contentValues.put(MediaStore.Audio.Media.ARTIST, videoInfo.details().author());
            contentValues.put(MediaStore.Audio.Media.IS_PENDING, 1);

            Uri collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
            Uri uriSaved =  context.getContentResolver().insert(collection, contentValues);

            try {
                ParcelFileDescriptor parcelFileDescriptor = context.getContentResolver().openFileDescriptor(uriSaved, "w");
                FileOutputStream fileOutputStream = new FileOutputStream(parcelFileDescriptor.getFileDescriptor());
                FileInputStream fileInputStream = new FileInputStream(downloadedFiles.get(0));
                byte[] buffer = new byte[1024];
                int length;
                while ((length = fileInputStream.read(buffer)) > 0) {
                    fileOutputStream.write(buffer, 0, length);
                }
                fileInputStream.close();
                fileOutputStream.close();
                contentValues.put(MediaStore.Audio.Media.IS_PENDING, 0);
                context.getContentResolver().update(uriSaved, contentValues, null, null);
            } catch (IOException e) {
                e.printStackTrace();
            }

            return uriSaved.toString();
        }

        return null;
    }

    public static String getMIMEType(String url) {
        String mType = null;
        String mExtension = MimeTypeMap.getFileExtensionFromUrl(url);
        if (mExtension != null) {
            mType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(mExtension);
        }
        return mType;
    }

    private List<String> downloadFormats(List<Format> formats) {
        List<String> downloadedFiles = new ArrayList<>(formats.size());

        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        final int[] progresses = new int[formats.size()];
        for(int i = 0; i < formats.size(); i++) {
            Format format = formats.get(i);
            ProgressUpdater.registerProgressUpdateCallback(downloadId, progressCallback);

            boolean isAudio = format instanceof AudioFormat;
            String filename = (isAudio ? "audio_" : "video_") + downloadId;
            int finalI = i;
            AtomicBoolean failed = new AtomicBoolean(false);
            RequestVideoFileDownload videoFileDownload = new RequestVideoFileDownload(format).callback(new YoutubeProgressCallback<File>() {
                @Override
                public void onDownloading(int progress) {
                    progresses[finalI] = progress;
                    int percent = 0; //(int) (progressStart + (progress * progressFactor));
                    ProgressUpdater.ProgressUpdate update = new ProgressUpdater.ProgressUpdate(false, getTotalProgress(progresses), downloadId, videoId);
                    ProgressUpdater.publishUpdate(downloadId, update);

                }

                @Override
                public void onFinished(File data) {
                    int percent = 100; //(int) (progressStart + (100 * progressFactor)
                    ProgressUpdater.ProgressUpdate update = new ProgressUpdater.ProgressUpdate(true, getTotalProgress(progresses), downloadId, videoId);
                    ProgressUpdater.publishUpdate(downloadId, update);
                }

                @Override
                public void onError(Throwable throwable) {
                    progresses[finalI] = -1;
                    ProgressUpdater.ProgressUpdate update = new ProgressUpdater.ProgressUpdate(true, -1, downloadId, videoId);
                    ProgressUpdater.publishUpdate(downloadId, update);

                    System.out.println("Error downloading video");
                    failed.set(true);
                }
            }).saveTo(context.getExternalFilesDir(Environment.DIRECTORY_MOVIES)).renameTo(filename);

            if(failed.get()) {
                throw new DownloadException("Error while Downloading");
            }

            File data = youtubeDownloader.downloadVideoFile(videoFileDownload).data();
            downloadedFiles.add(data.getAbsolutePath());
        }


        return downloadedFiles;
    }

    private static int getTotalProgress(int[] progresses) {
        if(progresses.length == 1) return progresses[0];
        int total = 0;
        for(int p : progresses) total += p;
        return (int)(total / 3.0f);
    }

}
