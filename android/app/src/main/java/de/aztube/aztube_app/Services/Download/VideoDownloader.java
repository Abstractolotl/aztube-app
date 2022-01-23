package de.aztube.aztube_app.Services.Download;

import android.content.Context;
import android.os.Environment;
import android.util.Log;
import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.FFmpegSession;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.YoutubeProgressCallback;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import de.aztube.aztube_app.DownloadUtil;
import org.jaudiotagger.audio.AudioFile;
import org.jaudiotagger.audio.AudioFileIO;
import org.jaudiotagger.tag.FieldKey;
import org.jaudiotagger.tag.Tag;
import org.jaudiotagger.tag.TagOptionSingleton;
import org.jaudiotagger.tag.images.ArtworkFactory;

import java.io.*;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class VideoDownloader {

    private final String DOWNLOAD_OUTPUT_DIR;

    private Context context;

    private final String videoId;
    private final int downloadId;

    private final String title;
    private final String author;
    private final String quality;

    private long videoDuration;

    private float videoInfoProgres;
    private float thumbnailProgress;
    private float filesProgress;
    private float ffmpegProgress;
    private float mediaStoreProgress;

    private List<File> cleanUp;

    public VideoDownloader(Context context, String videoId, int downloadId, String title, String author, String quality) {
        this.context = context;
        this.videoId = videoId;
        this.downloadId = downloadId;
        this.title = title;
        this.author = author;
        this.quality = quality;
        cleanUp = new LinkedList<>();

        DOWNLOAD_OUTPUT_DIR = context.getExternalFilesDir(Environment.DIRECTORY_MOVIES) + "/";
    }

    private void updateProgress(){
        float totalProgress =
                0.05f * videoInfoProgres +
                0.05f * thumbnailProgress +
                0.40f * filesProgress +
                0.45f * ffmpegProgress +
                0.05f * mediaStoreProgress;

        ProgressUpdater.publishUpdate(downloadId, new ProgressUpdater.ProgressUpdate(false, (int) totalProgress, downloadId, videoId));
    }

    public String startDownload(ProgressUpdater.ProgressUpdateCallback progressCallback) {
        ProgressUpdater.registerProgressUpdateCallback(downloadId, progressCallback);

        VideoInfo videoInfo = DownloadUtil.requestVideoInfo(videoId);
        List<Format> formats = DownloadUtil.pickVideoFormats(videoInfo, quality);
        videoDuration = formats.get(0).duration();
        videoInfoProgres = 100;
        updateProgress();

        String thumbnailoLcation = DOWNLOAD_OUTPUT_DIR + downloadId + "_thumbnail.jpg";
        DownloadUtil.downloadThumbnail(context, videoId, downloadId, thumbnailoLcation);
        thumbnailProgress = 100;
        updateProgress();

        File thumbnail = new File(thumbnailoLcation);
        List<File> downloadedFiles = downloadFormats(formats);
        filesProgress = 100;
        updateProgress();

        cleanUp.addAll(downloadedFiles);
        cleanUp.add(thumbnail);

        String outputFile = mergeFiles(downloadedFiles, thumbnail);
        cleanUpTmpFiles();
        updateProgress();

        return outputFile;
    }

    private String mergeFiles(List<File> files, File thumbnail) {
        if(quality.equals("audio")) {
            if(files.size() > 1) throw new DownloadException("What the hell is going on?");

            File audioFile = files.get(0);

            String tmp = DOWNLOAD_OUTPUT_DIR + title + "_ffmpeg.m4a";

            AtomicBoolean done = new AtomicBoolean();
            FFmpegKit.executeAsync("-i " + audioFile.getAbsolutePath() + " " + tmp,
                    (session) -> done.set(true),
                    null,
                    (statistics) -> {
                        ffmpegProgress = 100 * (statistics.getTime() / (float) videoDuration);
                        updateProgress();
                    });

            while(!done.get());
            ffmpegProgress = 100;
            updateProgress();


            File tmpFile = new File(tmp);
            cleanUp.add(tmpFile);

            TagOptionSingleton.getInstance().setAndroid(true);
            try {
                AudioFile f = AudioFileIO.read(tmpFile);
                Tag tag = f.getTag();
                tag.setField(FieldKey.TITLE, title);
                tag.setField(FieldKey.ARTIST, author);
                tag.setField(FieldKey.ALBUM_ARTIST, author);
                tag.setField(FieldKey.ALBUM, author + " - " + title);
                tag.setField(FieldKey.TRACK, "0");
                tag.setField(ArtworkFactory.createArtworkFromFile(thumbnail));
                AudioFileIO.write(f);

                String mediaStoreAdress = DownloadUtil.saveToMediaStore(context, tmpFile, title, author, downloadId).toString();
                mediaStoreProgress = 100;
                updateProgress();

                return mediaStoreAdress;
            } catch (Exception e) {
                e.printStackTrace();
                return null;
            }
        }

        return null;
    }

    private void cleanUpTmpFiles(){
        cleanUp.forEach(File::delete);
    }

    private List<File> downloadFormats(List<Format> formats) {
        List<File> downloadedFiles = new ArrayList<>(formats.size());

        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        final float[] progresses = new float[formats.size()];
        for(int i = 0; i < formats.size(); i++) {
            Format format = formats.get(i);

            boolean isAudio = format instanceof AudioFormat;
            String filename = downloadId + (isAudio ? "_audio" : "_video");
            int finalI = i;
            AtomicBoolean failed = new AtomicBoolean(false);
            RequestVideoFileDownload videoFileDownload = new RequestVideoFileDownload(format).callback(new YoutubeProgressCallback<File>() {
                @Override
                public void onDownloading(int progress) {
                    progresses[finalI] = progress;
                    filesProgress = getTotalProgress(progresses);
                    updateProgress();
                }

                @Override
                public void onFinished(File data) {
                    progresses[finalI] = 100;
                    filesProgress = getTotalProgress(progresses);
                    updateProgress();
                }

                @Override
                public void onError(Throwable throwable) {
                    System.out.println("Error downloading video");
                    failed.set(true);
                }
            }).saveTo(context.getExternalFilesDir(Environment.DIRECTORY_MOVIES)).renameTo(filename);

            if(failed.get()) {
                throw new DownloadException("Error while Downloading");
            }

            File data = youtubeDownloader.downloadVideoFile(videoFileDownload).data();
            downloadedFiles.add(data);
        }

        return downloadedFiles;
    }

    private static float getTotalProgress(float[] progresses) {
        if(progresses.length == 1) return progresses[0];
        int total = 0;
        for(float p : progresses) total += p;
        int progress = total / progresses.length;
        Log.d("AzTube", "PROGRESS " + progresses.length + " " + progress);
        return progress;
    }

}
