package de.aztube.aztube_app.Services.Download;

import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.Environment;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;
import android.util.Log;
import android.webkit.MimeTypeMap;
import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.FFmpegSession;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.YoutubeProgressCallback;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import de.aztube.aztube_app.DownloadUtil;
import de.aztube.aztube_app.Downloader;
import org.jaudiotagger.audio.AudioFile;
import org.jaudiotagger.audio.AudioFileIO;
import org.jaudiotagger.audio.AudioHeader;
import org.jaudiotagger.audio.exceptions.CannotReadException;
import org.jaudiotagger.audio.exceptions.InvalidAudioFrameException;
import org.jaudiotagger.audio.exceptions.ReadOnlyFileException;
import org.jaudiotagger.tag.FieldKey;
import org.jaudiotagger.tag.Tag;
import org.jaudiotagger.tag.TagException;
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

    private int totalProgress = 100;
    private int currentProgress = 0;
    private ProgressUpdater.ProgressUpdateCallback progressCallback;

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

    public String startDownload(ProgressUpdater.ProgressUpdateCallback progressCallback) {
        this.progressCallback = progressCallback;

        VideoInfo videoInfo = DownloadUtil.requestVideoInfo(videoId);
        List<Format> formats = DownloadUtil.pickVideoFormat(videoInfo, quality);

        String thumbnailoLcation = DOWNLOAD_OUTPUT_DIR + downloadId + "_thumbnail.jpg";
        DownloadUtil.downloadThumbnail(context, videoId, downloadId, thumbnailoLcation);

        File thumbnail = new File(thumbnailoLcation);
        List<File> downloadedFiles = downloadFormats(formats);
        cleanUp.addAll(downloadedFiles);
        cleanUp.add(thumbnail);

        String outputFile = mergeFiles(downloadedFiles, thumbnail);
        //cleanUpTmpFiles();

        return outputFile;
    }

    private String mergeFiles(List<File> files, File thumbnail) {
        if(quality.equals("audio")) {
            if(files.size() > 1) throw new DownloadException("What the hell is going on?");

            File audioFile = files.get(0);

            String tmp = DOWNLOAD_OUTPUT_DIR + title + "_ffmpeg.m4a";
            FFmpegKit.execute("-i " + audioFile.getAbsolutePath() + " " + tmp);
            cleanUp.add(new File(tmp));

            TagOptionSingleton.getInstance().setAndroid(true);
            try {
                DownloadUtil.saveAlbumCoverToMediaStore(context, thumbnail, title, downloadId);

                AudioFile f = AudioFileIO.read(new File(tmp));
                Tag tag = f.getTag();
                tag.setField(FieldKey.TITLE, title);
                tag.setField(FieldKey.ARTIST, author);
                tag.setField(FieldKey.ALBUM_ARTIST, author);
                tag.setField(FieldKey.ALBUM, author + title);
                tag.setField(FieldKey.TRACK, "0");
                tag.setField(ArtworkFactory.createArtworkFromFile(thumbnail));
                AudioFileIO.write(f);
                return DownloadUtil.saveToMediaStore(context, audioFile, title, author, downloadId).toString();
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

        final int[] progresses = new int[formats.size()];
        for(int i = 0; i < formats.size(); i++) {
            Format format = formats.get(i);
            ProgressUpdater.registerProgressUpdateCallback(downloadId, progressCallback);

            boolean isAudio = format instanceof AudioFormat;
            String filename = downloadId + (isAudio ? "_audio" : "_video");
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
            })
                    .saveTo(context.getExternalFilesDir(Environment.DIRECTORY_MOVIES)).renameTo(filename);

            if(failed.get()) {
                throw new DownloadException("Error while Downloading");
            }

            File data = youtubeDownloader.downloadVideoFile(videoFileDownload).data();
            downloadedFiles.add(data);
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
