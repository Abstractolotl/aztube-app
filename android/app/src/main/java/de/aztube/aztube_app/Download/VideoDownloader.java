package de.aztube.aztube_app.Download;

import android.content.Context;
import android.os.Environment;
import android.util.Log;
import com.arthenica.ffmpegkit.FFmpegKit;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.YoutubeProgressCallback;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
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


    private float videoInfoProgresFactor = 0.05f;
    private float videoInfoProgres;
    private float thumbnailProgressFactor = 0.05f;
    private float thumbnailProgress;
    private float filesProgressFactor = 0.30f;
    private float filesProgress;
    private float ffmpegProgressFactor = 0.55f;
    private float ffmpegProgress;
    private float mediaStoreProgressFactor = 0.05f;
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

    public String startDownload(ProgressUpdater.ProgressUpdateCallback progressCallback) {
        if(title == null) {
            Log.d("AzTube", "Title was null");
            return null;
        }
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

        String outputFile;
        try {
            outputFile = mergeFiles(downloadedFiles, thumbnail);
        } finally {
            cleanUp();
        }
        updateProgress();
        return outputFile;
    }

    private void updateProgress(){
        float totalProgress = videoInfoProgresFactor * videoInfoProgres +
                        thumbnailProgressFactor * thumbnailProgress +
                        filesProgressFactor * filesProgress +
                        ffmpegProgressFactor * ffmpegProgress +
                        mediaStoreProgressFactor * mediaStoreProgress;

        ProgressUpdater.publishUpdate(downloadId, new ProgressUpdater.ProgressUpdate(false, (int) totalProgress, downloadId, videoId));
    }

    private String mergeFiles(List<File> files, File thumbnail) {
        if(quality.equals("audio")) {
            if(files.size() > 1) throw new DownloadException("What the hell is going on? Too many files");
            return mergeAudio(files.get(0), thumbnail);
        }

        if(files.size() > 2) throw new DownloadException("What the hell is going on? Too many files");
        return mergeVideo(files);
    }

    private String mergeVideo(List<File> files){
        if(files.size() == 1) {
            filesProgressFactor += ffmpegProgressFactor;
            ffmpegProgressFactor = 0;

            File videoFile = files.get(0);
            try {
                String mediaStoreAdress = DownloadUtil.saveVideoToMediaStore(context, videoFile, title, author).toString();
                mediaStoreProgress = 100;
                updateProgress();
                return mediaStoreAdress;
            } catch (IOException e) {
                throw new DownloadException("Could now save to MediaStore", e);
            }
        }

        String tmp = DOWNLOAD_OUTPUT_DIR + downloadId + "_ffmpeg.mp4";
        File tmpFile = new File(tmp);
        cleanUp.add(tmpFile);

        int audioFileIndex;
        int videoFileIndex;
        if(DownloadUtil.getMIMEType(files.get(0)).toLowerCase().startsWith("audio")){
            audioFileIndex = 0;
            videoFileIndex = 1;
        } else {
            audioFileIndex = 1;
            videoFileIndex = 0;
        }

        AtomicBoolean done = new AtomicBoolean();
        String command = "-i \"" + files.get(audioFileIndex).getAbsolutePath() + "\" -i \"" + files.get(videoFileIndex).getAbsolutePath() + "\" -qscale:v 1 \"" + tmpFile.getAbsolutePath() + "\"";
        Log.d("AzTube", "FFMPEG COMMAND: " + command);
        FFmpegKit.executeAsync(command,
                (session) -> done.set(true),
                null,
                (statistics) -> {
                    ffmpegProgress = 100 * (statistics.getTime() / (float) videoDuration);
                    updateProgress();
                });

        try {
            //TODO: https://josephmate.wordpress.com/2016/02/04/how-to-avoid-busy-waiting/
            while(!done.get()) Thread.sleep(100);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        ffmpegProgress = 100;
        updateProgress();

        try {
            String mediaStoreAdress = DownloadUtil.saveVideoToMediaStore(context, tmpFile, title, author).toString();
            mediaStoreProgress = 100;
            updateProgress();
            return mediaStoreAdress;
        } catch (IOException e) {
            throw new DownloadException("Could now save to MediaStore", e);
        }
    }

    private String mergeAudio(File audioFile, File thumbnail){

        String tmp = DOWNLOAD_OUTPUT_DIR + downloadId + "_ffmpeg.m4a";
        File tmpFile = new File(tmp);
        cleanUp.add(tmpFile);

        AtomicBoolean done = new AtomicBoolean();
        FFmpegKit.executeAsync("-i \"" + audioFile.getAbsolutePath() + "\" \"" + tmpFile.getAbsolutePath() + "\"",
                (session) -> done.set(true),
                null,
                (statistics) -> {
                    ffmpegProgress = 100 * (statistics.getTime() / (float) videoDuration);
                    updateProgress();
                });

        try {
            //TODO: https://josephmate.wordpress.com/2016/02/04/how-to-avoid-busy-waiting/
            while(!done.get()) Thread.sleep(100);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        ffmpegProgress = 100;
        updateProgress();


        try {
            writeMetaInfoToAudioFile(tmpFile, thumbnail);

            String mediaStoreAdress = DownloadUtil.saveAudioToMediaStore(context, tmpFile, title, author).toString();
            mediaStoreProgress = 100;
            updateProgress();

            return mediaStoreAdress;
        } catch (Exception e) {
            throw new DownloadException("Could now save to MediaStore or write MetaInfo", e);
        }
    }

    private void writeMetaInfoToAudioFile(File file, File thumbnail) throws Exception {
        TagOptionSingleton.getInstance().setAndroid(true);
        AudioFile f = AudioFileIO.read(file);
        Tag tag = f.getTag();
        tag.setField(FieldKey.TITLE, title);
        tag.setField(FieldKey.ARTIST, author);
        tag.setField(FieldKey.ALBUM_ARTIST, author);
        tag.setField(FieldKey.ALBUM, author + " - " + title);
        tag.setField(FieldKey.TRACK, "0");
        tag.setField(ArtworkFactory.createArtworkFromFile(thumbnail));
        AudioFileIO.write(f);
    }

    private void cleanUp(){
        cleanUp.forEach(File::delete);
        ProgressUpdater.unregisterAllCallbacks(downloadId);
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
        float minProg = 100;
        for(float p : progresses) if(p < minProg) minProg = p;
        //int progress = total / progresses.length;
        return minProg;
    }

}
